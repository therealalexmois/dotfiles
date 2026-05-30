  Главное

  1. Самое срочное: zsh/.zshenv:2 без проверки грузит $HOME/.cargo/env, которого сейчас нет. Поэтому каждый
     shell-командный запуск печатает ошибку. Нужно либо установить rustup, либо обернуть source в if
     [ -f ... ].

  2. Homebrew-инвентарь устарел. mac-setup/brew-formulae.txt:1 похож на дамп всех formulae вместе с
     зависимостями, а не на список нужных инструментов. При этом в нем нет установленных вручную gh, glab,
     just, k9s, ollama, pnpm, stow, uv, yq. Лучше заменить txt-списки на Brewfile: это официальный сценарий
     Homebrew для фиксирования окружения и восстановления через brew bundle.

  3. Много пакетов реально отстали: neovim 0.11.4 -> 0.12.2, fzf, ripgrep, lazygit, tmux, starship, k9s,
     kubectl, ollama, uv, pyenv, poetry, postgresql@14, alacritty, pomatez, почти все Nerd Fonts.

  4. Neovim сейчас закреплен на AstroNvim v5: nvim/lua/lazy_setup.lua:4. В официальной миграции AstroNvim v6
     уже ориентируется на Neovim v0.12, новый LSP API и изменения Treesitter. Обновлять лучше через отдельный
     NVIM_APPNAME, не ломая рабочий nvim.

  5. README устарел сильнее, чем AGENTS.md: есть битый fence в README.md:128, старый Neovim 0.8+, fnm install
     17, ручной npm install -g pyright, и нет актуального stow --target "$HOME" bootstrap.

  Что заменить

  - the_silver_searcher -> убрать, оставить ripgrep.
  - pyenv + fnm -> рассмотреть mise, если хочешь один менеджер для Node/Python/tools/env/tasks.
  - poetry/pipx/часть pyenv -> рассмотреть uv, но только если готов мигрировать Python workflow.
  - mcfly -> atuin, если нужна синхронизация истории между рабочим и личным ноутбуком; иначе можно оставить
    mcfly.

  - Добавить zoxide: README уже его рекомендует, но в formulae и .zshrc он не подключен.
  - Добавить eza для человекочитаемого ls/tree; tree можно оставить для скриптов.
  - htop/bottom/procs: выбрать 1-2. Я бы оставил bottom для dashboard и procs для списка процессов.
  - dust/gdu: выбрать по привычке. Если один инструмент, я бы оставил gdu для анализа диска.

  Отдельные несостыковки

  - alacritty/alacritty.toml:2 импортирует ~/.config/alacritty/..., а dotfiles живут в $HOME/.dotfiles. Нужно
    проверить, что symlink реально есть.

  - wezterm/wezterm.lua:23 задает строку "$HOME/.dotfiles" буквально; в Lua лучше os.getenv("HOME") ..
    "/.dotfiles".

  - nvim/lua/config/ai/codecompanion_profiles.lua:4 использует qwen2.5-coder:7b. Он еще валиден, но в Ollama
    уже есть более новые coder-модели; менять стоит только после проверки tool calling и скорости на ноутбуке.

  Я бы обновлял так

  1. Исправить shell warning и README/bootstrap docs.
  2. Перевести Homebrew на mac-setup/Brewfile, убрать зависимости и лишние Nerd Fonts.
  3. Обновить Homebrew-пакеты.
  4. Отдельно мигрировать AstroNvim v5 -> v6 в изолированном профиле.
  5. Потом решить по заменам: mise/uv/atuin/eza/zoxide.

  Сверял с текущими docs: AstroNvim v6 migration (https://docs.astronvim.com/configuration/v6_migration/),
  Homebrew Bundle (https://docs.brew.sh/Brew-Bundle-and-Brewfile), mise
  (https://mise.jdx.dev/getting-started.html), uv (https://docs.astral.sh/uv/), Atuin
  (https://docs.atuin.sh/cli/), eza (https://github.com/eza-community/eza).
