"""Читает и объединяет глобальный профиль Team Lead и проектное дополнение."""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

PROFILE_SECTIONS = (
    'Параметры', 'Worktree', 'Проверки', 'Исполнители', 'Ревьюеры',
    'Гейты', 'Вливание', 'Подводные камни',
)
TASK_BLOCKS = ('task-context', 'task-criteria', 'task-constraints', 'report-extra')
MARKER = re.compile(r'<!-- (/?)team-lead:([a-z]+(?:-[a-z]+)*) -->')


@dataclass(frozen=True)
class SourcedText:
    """Хранит текст и его происхождение: глобальный или проектный профиль."""

    text: str
    source: str


@dataclass
class Profile:
    """Хранит разделы, параметры и независимые блоки задания.

    Attributes:
        paths: Прочитанные файлы в порядке приоритета.
        preamble: Заголовок и вводный текст до первого раздела.
        sections: Разделы второго уровня без блоков задания.
        parameters: Значения таблицы «Параметры» по ключам.
        blocks: Тексты между парными маркерами по имени блока.
    """

    paths: tuple[Path, ...]
    preamble: str
    sections: dict[str, SourcedText] = field(default_factory=dict)
    parameters: dict[str, SourcedText] = field(default_factory=dict)
    blocks: dict[str, SourcedText] = field(default_factory=dict)


def split_sections(text: str, allowed: tuple[str, ...]) -> tuple[str, dict[str, str]]:
    """Разбирает разделы вне огражденных блоков кода; отвергает неизвестные и дубли.

    Returns:
        Вводный текст и тела разделов в исходном порядке.
    """
    sections: dict[str, list[str]] = {}
    preamble: list[str] = []
    body = preamble
    fence: str | None = None
    for line in text.splitlines():
        delimiter = re.match(r'^\s{0,3}(`{3,}|~{3,})', line)
        if delimiter:
            token = delimiter.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None

        heading = re.match(r'^## +(.+?)\s*$', line) if fence is None else None
        if heading:
            title = heading.group(1)
            if title not in allowed:
                raise ValueError(f'unknown section {title!r}; allowed: {list(allowed)}')
            if title in sections:
                raise ValueError(f'duplicate section: {title}')
            body = []
            sections[title] = body
        else:
            body.append(line)

    return '\n'.join(preamble).strip(), {
        title: '\n'.join(lines).strip() for title, lines in sections.items()
    }


def extract_blocks(text: str) -> tuple[str, dict[str, str]]:
    """Извлекает блоки до разбора разделов, проверяя маркеры и непустые тела."""
    remaining: list[str] = []
    blocks: dict[str, str] = {}
    active: str | None = None
    body: list[str] = []
    for index, line in enumerate(text.splitlines(), 1):
        marker = MARKER.fullmatch(line)
        if not marker:
            if re.search(r'<!--\s*/?team-lead\b', line):
                raise ValueError(f'broken block marker at line {index}')
            (body if active else remaining).append(line)
            continue

        closing, name = marker.groups()
        if name not in TASK_BLOCKS:
            raise ValueError(f'unknown task block: {name}')
        if closing:
            if active != name:
                raise ValueError(f'unmatched closing block {name} at line {index}')
            content = '\n'.join(body).strip()
            if not content:
                raise ValueError(f'empty task block: {name}')
            blocks[name] = content
            active = None
            body = []
        else:
            if active:
                raise ValueError(f'nested block {name} inside {active}')
            if name in blocks:
                raise ValueError(f'duplicate task block: {name}')
            active = name

    if active:
        raise ValueError(f'unclosed task block: {active}')

    return '\n'.join(remaining), blocks


def parse_parameters(text: str) -> dict[str, str]:
    """Читает таблицу из двух колонок без пустых значений и повторов ключей."""
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if len(lines) < 2 or not re.fullmatch(r'\|\s*Ключ\s*\|\s*Значение\s*\|', lines[0]):
        raise ValueError('parameters must start with | Ключ | Значение |')
    if not re.fullmatch(r'\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|', lines[1]):
        raise ValueError('parameters table has no valid separator')

    parameters: dict[str, str] = {}
    for line in lines[2:]:
        row = re.fullmatch(r'\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|', line)
        if not row:
            raise ValueError('parameters must contain two-column rows')
        key, value = row.groups()
        if key.startswith('`') and key.endswith('`'):
            key = key[1:-1]
        if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', key) or not value.strip():
            raise ValueError('parameter key or value is empty or invalid')
        if key in parameters:
            raise ValueError(f'duplicate parameter: {key}')
        parameters[key] = value.strip()

    return parameters


def read_profile(path: Path, source: str) -> Profile:
    """Читает один профиль; обязательность task-context проверяет сборщик задания."""
    try:
        remaining, blocks = extract_blocks(path.read_text(encoding='utf-8'))
        preamble, sections = split_sections(remaining, PROFILE_SECTIONS)
        if not sections and not blocks:
            raise ValueError('profile has no sections or task blocks')
        parameters = parse_parameters(sections['Параметры']) if 'Параметры' in sections else {}
    except ValueError as error:
        raise ValueError(f'{path}: {error}') from None

    return Profile(
        paths=(path,), preamble=preamble,
        sections={name: SourcedText(body, source) for name, body in sections.items()},
        parameters={key: SourcedText(value, source) for key, value in parameters.items()},
        blocks={name: SourcedText(body, source) for name, body in blocks.items()},
    )


def repo_name(repo: Path) -> str | None:
    """Находит имя основного checkout через общий каталог Git.

    Returns:
        Имя основного checkout либо None вне репозитория.

    Raises:
        ValueError: Каталог не существует, Git вернул ошибку или его структура не поддерживается.
    """
    directory = repo.expanduser().resolve()
    if not directory.is_dir():
        raise ValueError(f'repo directory does not exist: {directory}')
    result = subprocess.run(
        ['git', '-C', str(directory), 'rev-parse', '--git-common-dir'],
        capture_output=True, text=True, check=False, env={**os.environ, 'LC_ALL': 'C'},
    )
    if result.returncode:
        if 'not a git repository' in result.stderr:
            return None
        raise ValueError(f'git-common-dir failed: {result.stderr.strip()}')

    common = (directory / result.stdout.strip()).resolve()
    if common.name != '.git':
        raise ValueError(f'unsupported common Git directory: {common}')

    return common.parent.name


def resolve_paths(repo: Path) -> tuple[Path, ...]:
    """Возвращает найденные пути; глобальный профиль обязателен в любом каталоге."""
    root = Path(os.environ.get('XDG_DATA_HOME') or Path.home() / '.local' / 'share').expanduser()
    directory = root / 'team-lead'
    global_path = directory / 'profile.md'
    if not global_path.is_file():
        raise ValueError(f'global profile not found: {global_path}; see references/profile-format.md')

    name = repo_name(repo)
    project_path = directory / 'projects' / f'{name}.md' if name else None
    if project_path is not None:
        if (project_path.exists() or project_path.is_symlink()) and not project_path.is_file():
            raise ValueError(f'project profile is not a file: {project_path}')
        if project_path.is_file():
            return global_path, project_path

    return (global_path,)


def load_profile(repo: Path) -> Profile:
    """Объединяет разделы, ключи параметров и блоки; проект имеет приоритет."""
    paths = resolve_paths(repo)
    merged = read_profile(paths[0], 'глобальный')
    if len(paths) == 1:
        return merged

    project = read_profile(paths[1], 'проектный')
    sections = merged.sections | project.sections
    parameters = merged.parameters | project.parameters
    if parameters:
        sources = ', '.join(dict.fromkeys(value.source for value in parameters.values()))
        sections['Параметры'] = SourcedText('', sources)

    return Profile(
        paths=paths, preamble=project.preamble or merged.preamble,
        sections=sections, parameters=parameters,
        blocks=merged.blocks | project.blocks,
    )


def render_profile(profile: Profile, *, sources: bool = True) -> str:
    """Печатает профиль, помечая источник разделов, ключей и блоков вне их тел."""
    parts = [profile.preamble] if profile.preamble else []
    for name, section in profile.sections.items():
        parts.append(f'## {name}')
        if sources:
            parts.append(f'<!-- Источник: {section.source} -->')
        if name == 'Параметры':
            rows = ['| Ключ | Значение |', '| --- | --- |']
            for key, value in profile.parameters.items():
                note = f' <!-- Источник: {value.source} -->' if sources else ''
                rows.append(f'| `{key}` | {value.text}{note} |')
            parts.append('\n'.join(rows))
        elif section.text:
            parts.append(section.text)

    for name, block in profile.blocks.items():
        if sources:
            parts.append(f'<!-- Источник блока {name}: {block.source} -->')
        parts.append(f'<!-- team-lead:{name} -->\n{block.text}\n<!-- /team-lead:{name} -->')

    return '\n\n'.join(parts) + '\n'
