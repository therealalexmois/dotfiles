# Alacritty на macOS

Homebrew cask отключен. Устанавливайте приложение из исходников по
[официальной инструкции](https://github.com/alacritty/alacritty/blob/master/INSTALL.md#macos).
Выбирайте тег из [стабильных релизов](https://github.com/alacritty/alacritty/releases/latest),
а не `master`, где идет разработка следующей версии.

## Установка

Нужны Xcode Command Line Tools (`xcode-select --install`),
[Rust через rustup](https://rustup.rs/) и `scdoc` (`brew install scdoc`).
В рабочем каталоге вне `~/.dotfiles` выполните:

```sh
alacritty_tag=v0.17.0 # Замените на выбранный стабильный тег.
git clone --branch "$alacritty_tag" https://github.com/alacritty/alacritty.git
cd alacritty
rustup override set stable
rustup update stable
make app
target/release/osx/Alacritty.app/Contents/MacOS/alacritty --version
```

После успешной сборки закройте Alacritty и продолжите в другом терминале.
Если приложение установлено через Homebrew, сначала выполните
`brew uninstall --cask alacritty`, чтобы Homebrew больше не управлял этой копией.
Затем установите собранное приложение:

```sh
cp -r target/release/osx/Alacritty.app /Applications/
/Applications/Alacritty.app/Contents/MacOS/alacritty --version
```

Для подключения конфигурации этого репозитория нужен GNU Stow (`brew install stow`):

```sh
~/.dotfiles/bootstrap/install-alacritty.sh
```

## Обновление

В сохраненном каталоге исходников задайте новый `alacritty_tag`, затем выполните
`git fetch origin tag "$alacritty_tag"` и `git checkout --detach "$alacritty_tag"`.
Повторите сборку, проверку версии и копирование приложения из раздела установки.
Удалять Homebrew cask повторно не нужно. Конфигурация в `~/.config/alacritty`
сохраняется.
