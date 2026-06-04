# AstroNvim Template

**NOTE:** This is for AstroNvim v5+

A template for getting started with [AstroNvim](https://github.com/AstroNvim/AstroNvim)

## 🛠️ Installation

#### Make a backup of your current nvim and shared folder

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### Create a new user repository from this template

Press the "Use this template" button above to create a new repository to store your user configuration.

You can also just clone this repository directly if you do not want to track your user configuration in GitHub.

#### Clone the repository

```shell
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim
```

#### Start Neovim

```shell
nvim
```

## 🤖 AI integration

Two independent surfaces live side by side:

- **CodeCompanion** (`<leader>A`) — multi-model code operations (chat, inline edits,
  prompt library). Switchable adapters: local Ollama, an HTTP work proxy, and Claude over
  ACP on a subscription.
- **claudecode.nvim** (`<leader>C`) — the `claude` CLI over the official IDE protocol for
  agentic and research work with native accept/reject diffs. It inherits the CLI's MCP
  servers, subagents, skills, and rules; nothing extra to configure in Neovim.

### Profiles and model switching

`NVIM_AI_PROFILE` selects the default CodeCompanion adapter:

| Value | Default chat adapter | Inline / cmd adapter |
| --- | --- | --- |
| `home` (default) | Ollama (local) | Ollama (local) |
| `work` | work proxy (HTTP) | work proxy (HTTP) |
| `claude` | `claude_code` (ACP) | Ollama/work proxy |

Inline edits always stay on the HTTP adapters; only chat routes to ACP under the `claude`
profile. Run `:AIProfileStatus` to see the active profile and preflight result. Claude
chat is also reachable from any profile with `<leader>Al`, and `<leader>Cm` selects the
model inside `claudecode.nvim`.

### Key maps

| Keys | Action |
| --- | --- |
| `<leader>AA` | CodeCompanion action palette |
| `<leader>Ac` | CodeCompanion chat toggle |
| `<leader>Aq` | Add selection to chat (visual) |
| `<leader>Al` | Claude chat over ACP |
| `<leader>Cc` | Toggle Claude Code |
| `<leader>Cs` | Send selection to Claude (visual) |
| `<leader>Ca` / `<leader>Cd` | Accept / deny the proposed diff |
| `<leader>CR` | Seed a research-report prompt (`:ClaudeResearch`) |
| `<leader>Cm` | Select Claude model |

### Prompt library

Reusable prompts load from `~/.dotfiles/llm/prompts/` into the action palette and as
`/alias` slash commands in chat: `explain`, `fix`, `lsp`, `review`, `refactor`,
`unit-tests`, `commit`, and more. See `llm/PROMPT_POLICY.md` for the contract.

### One-time setup

- `claudecode.nvim` works as soon as the `claude` CLI is installed and logged in.
- The CodeCompanion `claude` profile needs the ACP bridge:
  `npm install -g @zed-industries/claude-code-acp`.
- Optional, for seamless ACP auth: `claude setup-token`, then export
  `CLAUDE_CODE_OAUTH_TOKEN` from your local shell env. Treat it as a secret; never commit
  it. ACP still works without it on an interactive subscription.
