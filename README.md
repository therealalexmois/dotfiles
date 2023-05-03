# dotfiles

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
