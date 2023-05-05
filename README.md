# dotfiles

## System Settings
- set caps lock to escape
- bump key repeat up by one notch
- set turn display off after 20 mins while on battery 30 mins while charging
- turn on night shift

## Command Line Tools
```sh
xcode-select --install
```

## Install brew
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /Users/chris/.zprofile

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/chris/.zprofile

eval "$(/opt/homebrew/bin/brew shellenv)"

brew analytics off
```

For Mac OS:

```sh
brew install nvim

brew install rust-analyzer

brew install ripgrep

brew install fd

brew tap homebrew/cask-fonts && brew install --cask font-jetbrains-mono-nerd-font

npm install -g pyright
```

```sh
brew install lazygit
```

Next we need to install python support (node is optional)

- Neovim python support

  ```
  pip install pynvim
  ```

- Neovim node support

  ```
  npm i -g neovim
  ```
---

## Requirements
- [Nerd Fonts](https://www.nerdfonts.com/font-downloads) (Optional with manual intervention: See Documentation on customizing icons)
- [Neovim 0.8+ (Not including nightly)](https://github.com/neovim/neovim/releases/tag/stable)
- [Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/blob/master/cli/README.md) (Note: This is only necessary if you want to use auto_install feature with Treesitter)
- A clipboard tool is necessary for the integration with the system clipboard (see [:help clipboard-tool](https://neovim.io/doc/user/provider.html#clipboard-tool) for supported solutions)
- Terminal with true color support (for the default theme, otherwise it is dependent on the theme you are using)
- [ripgrep](https://github.com/BurntSushi/ripgrep) - live grep telescope search (<leader>fw)
- [lazygit](https://github.com/jesseduffield/lazygit) - git ui toggle terminal (<leader>tl or <leader>gg)
- [Python](https://www.python.org/) - python repl toggle terminal (<leader>tp)
- [Node](https://nodejs.org/en) - node repl toggle terminal (<leader>tn)

## ![Installation](https://github.githubassets.com/images/icons/emoji/unicode/1f6e0.png) Installation

## Macos misc
- [macOS system monitor](https://github.com/exelban/stats)
- [clock](https://www.mowglii.com/itsycal/)

## Content Creation
```sh
brew install obs     # to record my screen
brew install gimp    # image editing
brew install blender # video editing
```

## Improving the Launcher
```sh
brew install raycast
```

## Window Management
```sh
brew install rectangle
```

## CLI utilities
```sh
brew install tree    # allows you to see the outline of a directory 
brew install zoxide  # jump anywhere within your filesystem with z <foldername>
brew install ripgrep # blazingly fast grep
brew install fd      # blazingly fast find
```

## FZF
```sh
brew install fzf
$(brew --prefix)/opt/fzf/install
```

After installation you will be able to press control-r to interactively search history

Also you can pipe any output in to fzf and fuzzy search over it for example:

```sh
brew list | fzf
```

## Terminal System Monitors
```sh
brew install htop
brew install glances
brew install lazygit
```

## Web Tools
```sh
brew install insomnia
brew install wget
brew install httpie
brew install jq
brew install ngrok
npm install -g http-server
```

## Documentation
```sh
brew install tldr
```

## Programming Languages
### Python
```sh
echo "alias python=/usr/bin/python3" >> ~/.zshrc
echo "alias pip=/usr/bin/pip3" >> ~/.zshrc
```

Install miniforge for apple silicon:
```sh
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh -O ~/miniforge.sh

sh ~/miniforge.sh -b -f -p  $HOME/.miniforge

rm ~/miniforge.sh
```

Add the following in your .zshrc file:
```sh
if [ -f "$HOME/.miniforge/etc/profile.d/conda.sh" ]; then
      . "$HOME/.miniforge/etc/profile.d/conda.sh"
  else
      export PATH="$HOME/.miniforge/bin:$PATH"
fi
```

Open up a new terminal and the conda command should be available, if you don’t want to activate the base environment run the following:

```sh
conda config --set auto_activate_base false
```

### Node
```sh
brew install fnm

echo '"$(fnm env --use-on-cd)"' >> /Users/chris/.zprofile

fnm install 17
```

### Rust
This should be all you need to install rust.
```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Go
```sh
brew install go
```

I hate that they put a go directory right in my home directory. I personally change the GOPATH like this:

```sh
export GOPATH=$HOME/.local/share/go
export PATH=$HOME/.local/share/go/bin:$PATH
```

then remove the other one:

```sh
sudo rm -rf ~/go
```

## Install Neovim
Neovim is my text editor of choice

I install Neovim from source you can probably just:

```sh
brew install neovim
```

## Rosetta

Rosetta will allow you to run software compiled for x86_64 architecture on Apple silicon.

```sh
softwareupdate --install-rosetta
```

## Docker
Follow the instructions at the following link to install docker desktop for Apple silicon.

[docker desktop](https://docs.docker.com/desktop/install/mac-install/)

```sh
brew install lazydocker
```

Make sure to stop docker desktop after installing and set it to not auto-start since it is pretty resource hungry.

## Install my dotfiles
```sh
brew install stow
git clone https://github.com/therealalexmois/dotfiles.git
```

## Nerd fonts
```sh
brew install fontconfig
```

Useful gist for install fonts: [font gist](https://gist.github.com/davidteren/898f2dcccd42d9f8680ec69a3a5d350e)

You can also download your own fonts and place them in ~/Library/Fonts


