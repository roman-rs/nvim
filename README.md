# Neovim configuration

## Installation

Install the dependencies below, then clone this repository into Neovim's configuration directory:

```sh
git clone https://github.com/roman-rs/nvim "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim
```

The first launch bootstraps lazy.nvim and installs plugins. Run `:Lazy restore` to
restore the plugin revisions recorded in `lazy-lock.json`. Tree-sitter parsers
install asynchronously on startup; use `:TSUpdate` after updating nvim-treesitter.

## Dependencies and versions

Version inventory checked on **2026-11-04**. External tool versions below are the
installed versions on the current Linux setup, not package pins. Plugin and parser
versions are commit revisions. Where a tool is configured but absent, its version
is explicitly marked **not installed / unpinned** rather than implying it was tested.

### Core tools and build dependencies

| Dependency | Installed version | Requirement / purpose |
| --- | --- | --- |
| Neovim | **0.12.6** | **0.12.0+**, required by the pinned nvim-treesitter `main` branch; also provides the LSP, floating-window, OSC 52, and process APIs used here |
| LuaJIT | **2.1.1774638290** | Bundled with this Neovim build; no separate Lua installation needed |
| Git | **2.43.0** | Plugin bootstrap, Git pickers, floating Git status, and Fugitive; lazy.nvim requires Git **2.19.0+** |
| fzf | **0.72.0** (`6fefe025`) | External fuzzy-finder executable for fzf-lua; use **0.53.0+** for modern UI flags, upstream baseline is **0.36+** |
| ripgrep (`rg`) | **12.1.0** (`1980630f17`) | Project/live grep and source lookup for macro argument definitions |
| fd (`fdfind` on Ubuntu) | **9.0.0** | Recommended fast file enumeration; fzf-lua auto-detects `fdfind`, then `fd`, and falls back to `rg`/`find` |
| Tree-sitter CLI (`tree-sitter`) | **0.27.0** | **0.26.1+** for the pinned nvim-treesitter; install through a system package manager or standalone release, not npm |
| C compiler (`cc` / GCC) | **GCC 13.3.0** | Builds Tree-sitter parsers and LuaSnip's jsregexp extension; upstream does not pin a compiler version |
| GNU Make | **4.3** | LuaSnip's `make install_jsregexp` build and the C/C++ `<F5>` project-build mapping |
| curl | **8.5.0** | Required by nvim-treesitter to download parser sources; also used by Mason |
| GNU tar | **1.35** | Parser downloads and Mason package extraction |
| GNU wget | **1.21.4** | Alternative downloader for Mason; curl remains required for Tree-sitter |
| UnZip | **6.00** | Mason package extraction |
| gzip | **1.12** | Mason package extraction |
| Universal Ctags | **5.9.0** | Tagbar (`<F9>`); optional if Tagbar is not used |

The pinned Tree-sitter requirements are documented in
[nvim-treesitter's README](https://github.com/nvim-treesitter/nvim-treesitter/blob/427e9222363d07c32d6db6169e4049c28d58d141/README.md).
Neovim's built-in Tree-sitter runtime currently supports parser ABI **13–15**;
it is separate from the external CLI used to generate parsers.

### Language servers, language runtimes, and optional preview tools

Language servers are configured in `lua/config/nvim-cmp.lua`. Mason provides an
installation UI (`:Mason`), but this configuration does **not** automatically
install or pin language-server packages. Executables must be on Neovim's PATH.

| Dependency | Version / current status | Purpose |
| --- | --- | --- |
| clangd | **18.1.3** | C/C++ LSP, macro hover expansions, and generated-declaration previews; this version was used for verification |
| clang-format / clang-format-18 | **Not installed / unpinned** | Optional formatting of generated declaration previews; **18.x** is a natural companion to clangd 18, but is not a configured requirement |
| rust-analyzer | **Not installed / unpinned** | Rust LSP; select a release compatible with the project's Rust toolchain |
| rustc, Cargo, Clippy | **Not installed / unpinned** | Rust project analysis, build scripts, `cargo clippy`, and the Rust `<F5>` mapping (`cargo run`); use the project's toolchain version |
| Perl Navigator (`perlnavigator`) | **Not installed / unpinned** | Perl LSP; install a standalone release or `perlnavigator-server` through npm |
| Perl | **5.38.2** | Perl Navigator syntax checking; upstream reports support back to **5.8** |
| Node.js / npm | **Not installed / unpinned** | Needed when installing/running the npm distribution of Perl Navigator; not needed for its standalone binary; use the selected package's engine requirements |
| python-lsp-server (`pylsp`) | **Not installed / unpinned** | Python LSP |
| Python | **3.12.3** (`python3`) | Runtime for Python tooling; choose package versions that support this interpreter |
| Pylint | **Not installed / unpinned** | Enabled Python diagnostics |
| python-lsp-black / Black | **Not installed / unpinned** | Enabled Python formatter; the pylsp integration package is required in the server's environment |
| python-lsp-isort / isort | **Not installed / unpinned** | Enabled import sorting; install the pylsp integration in the server's environment |
| bat / batcat | **Not installed / unpinned** | Optional syntax highlighting for native fzf previews; regular previews use Neovim's builtin previewer |
| git-delta (`delta`) | **Not installed / unpinned** | Optional Git/code-action diff pager; automatically detected, with builtin code-action preview fallback |

For accurate C/C++ analysis, supply the project's `compile_commands.json` or
equivalent `.clangd` compile flags. Macro previews use clangd's actual preprocessing
context; they do not execute code actions or apply edits to the source.

Terminal icons require a Nerd Font or another font with the relevant glyphs
(**no font family/version is pinned**). Clipboard copying uses **OSC 52**; the
terminal must support it. If using tmux, enable `set-clipboard on` and
`allow-passthrough on` (**tmux is optional and its version is not pinned**).

### Enabled Neovim plugins

lazy.nvim installs these plugins automatically. The exact version is the commit
in `lazy-lock.json`; abbreviated revisions below identify those pins. Use the lock
file for the full 40-character hashes.

| Plugin | Pinned revision | Purpose |
| --- | --- | --- |
| `folke/lazy.nvim` | `306a05526ada` | Plugin manager |
| `ibhagwan/fzf-lua` | `05e44d38de0a` | File, buffer, grep, Git, LSP, and history pickers |
| `nvim-tree/nvim-web-devicons` | `5f032a85be21` | File icons shared by several plugins |
| `neovim/nvim-lspconfig` | `ee1e369181a9` | Language-server configuration |
| `mason-org/mason.nvim` | `2a6940af8037` | External tooling installation UI |
| `nvimdev/lspsaga.nvim` | `cf6fc9473bba` | Hover documentation and code-action lightbulb |
| `hrsh7th/nvim-cmp` | `2ffe79f1f021` | Completion engine |
| `hrsh7th/cmp-nvim-lsp` | `cbc7b02bb99f` | LSP completion source and capabilities |
| `hrsh7th/cmp-nvim-lsp-signature-help` | `fd3e882e5695` | Signature-help completion source |
| `hrsh7th/cmp-buffer` | `b74fab3656ee` | Buffer completion source |
| `hrsh7th/cmp-path` | `c642487086db` | Path completion source |
| `hrsh7th/cmp-cmdline` | `d126061b624e` | Command-line completion source |
| `L3MON4D3/LuaSnip` | `642b0c595e11` | Snippet expansion; spec requests `v2.*`, exact version comes from the lock file |
| `onsails/lspkind.nvim` | `c7274c481373` | Completion-kind icons |
| `nvim-treesitter/nvim-treesitter` (`main`) | `427e9222363d` | Parser installation and syntax queries |
| `lukas-reineke/indent-blankline.nvim` | `d28a3f70721c` | Indentation/scope highlighting |
| `nvim-lualine/lualine.nvim` | `221ce6b2d999` | Status line |
| `OXY2DEV/markview.nvim` | `5d9fc2aa6dd1` | Markdown rendering |
| `0xfraso/nvim-listchars` | `694349b66418` | Whitespace character display |
| `NLKNguyen/papercolor-theme` | `0cfe64ffb24c` | PaperColor theme |
| `folke/persistence.nvim` | `b20b2a7887bd` | Session persistence |
| `akinsho/git-conflict.nvim` | `4bbfdd92d547` | Merge-conflict helpers; spec requests `*`, lock file pins the revision |
| `tpope/vim-fugitive` | `3b753cf8c6a4` | Git integration |
| `preservim/tagbar` | `07cb82474872` | Ctags-based symbol outline |
| `MattesGroeger/vim-bookmarks` | `9cc5fa7ecc23` | Bookmarks |

Copilot, CtrlP, Snacks, rust-tools, and the standalone whitespace-highlight plugin
are disabled in the current plugin specs. Their dependencies are not required;
the remaining Copilot entry in `lazy-lock.json` is not an enabled dependency.

### Tree-sitter parsers

`lua/plugins/treesitter.lua` installs the following parsers. Their source revisions
are specified by the pinned nvim-treesitter plugin's `lua/nvim-treesitter/parsers.lua`,
not by separate entries in this repository's lock file. Updating nvim-treesitter
can change these revisions.

| Parser | Source revision |
| --- | --- |
| `markdown` | `a0a00f817d02` |
| `markdown_inline` | `a0a00f817d02` (same repository, separate grammar) |
| `lua` | `10fe0054734e` |
| `vim` | `039c8d0aa1de` |
| `vimdoc` | `23daa416c1ff` |
| `query` | `8e9e223812ff` |
| `bash` | `a06c2e4415e9` |
| `c` | `b780e47fc780` |
| `cpp` | `8b5b49eb196b` |
| `json` | `254c42a64764` |
| `yaml` | `a1c4812a73ec` |
| `perl` | `c3e17b31179bf` (requires CLI generation) |
| `php` | `3fda2fb95771` |

The `c`/`cpp` parsers also support identifying enclosing macro calls and generated
declarations in the custom macro-preview module.

### Checking the local installation

Useful Neovim checks:

```vim
:checkhealth
:checkhealth nvim-treesitter
:checkhealth fzf-lua
:checkhealth mason
:checkhealth vim.lsp
:Lazy
:Mason
```

Check external versions in a terminal:

```sh
nvim --version
git --version
fzf --version
rg --version
fdfind --version     # or fd --version
tree-sitter --version
clangd --version
ctags --version
```

For tools installed by Mason, check executable availability from inside Neovim,
since Mason's bin directory may not be on the shell's PATH:

```vim
:lua print(vim.fn.exepath("clangd"))
:lua print(vim.fn.exepath("rust-analyzer"))
:lua print(vim.fn.exepath("perlnavigator"))
:lua print(vim.fn.exepath("pylsp"))
```
