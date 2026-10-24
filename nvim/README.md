# Neovim configuration

This directory configures Neovim with AstroNvim v6.
Install it as part of the [dotfiles setup](../docs/how-to/install.md).
Do not clone it separately into `~/.config/nvim`.

## Start Neovim

Requirements:

- Neovim 0.11 or later.
- A configured shell with `XDG_CONFIG_HOME=$HOME/.dotfiles`.
- A Nerd Font and a clipboard provider. See `:help clipboard-tool`.
- Network access for the first lazy.nvim/plugin bootstrap.

From a configured terminal:

```sh
nvim
```

The leader key is Space. The local leader is comma.

## Verify config loading

Inside Neovim:

```vim
:echo stdpath('config')
```

The result should be your home path followed by `/.dotfiles/nvim`.
A GUI launcher without the shell environment may load `~/.config/nvim` instead.

## Find a workflow

| Task | Document or keys |
| --- | --- |
| AI chat, code edits, and background jobs | [AI reference](AI.md) |
| Python debugging | [DAP guide](DAP.md) |
| Reusable AI prompts | [Prompt library](../llm/README.md) |
| Find text | `<leader>fw`, with ripgrep |
| Git UI | `<leader>tl` or `<leader>gg`, with lazygit |
| Disk usage | `<leader>tu`, with gdu |
| Process viewer | `<leader>tt`, with bottom |
| Python or Node REPL | `<leader>tp` or `<leader>tn` |

## Configuration files

```text
init.lua
└── lua/lazy_setup.lua
    ├── AstroNvim v6
    ├── lua/community.lua
    └── lua/plugins/
        ├── ai/
        ├── debugging/
        ├── editing/
        └── ui/
```

Keep plugin revisions in `lazy-lock.json`. Update it through the plugin manager.
Language servers and debugging tools use Mason.
Python/Node Neovim host packages are optional unless a plugin needs them.
Tree-sitter auto-install may require the Tree-sitter CLI.

For changes to this directory, follow [the local instructions](AGENTS.md).
