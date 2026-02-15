# vim-mplus

Vim plugin for [Mplus](https://www.statmodel.com/) statistical software files (`.inp` and `.out`).

## Features

- Syntax highlighting for keywords, commands, model operators, section headers, and comments
- Syntax-based folding for input sections and output blocks
- Indentation (section headers at column 0, body indented)
- Omni-completion (`<C-x><C-o>`) for all Mplus keywords via `syntaxcomplete`
- [UltiSnips](https://github.com/SirVer/ultisnips) snippets for common analyses (CFA, SEM, LGM, LCA, and more)

## Installation

Using a plugin manager (e.g., vim-plug):

```vim
Plug 'li-ruijie/vim-mplus'
```

Or copy the contents to your Vim runtime directory.

## Commands

| Command | Description                                  |
|---------|----------------------------------------------|
| `:Mout` | Open corresponding `.out` file in vertical split |
| `:Mrun` | Run Mplus on current file (Windows)          |

## Snippets

Requires [UltiSnips](https://github.com/SirVer/ultisnips). Type the trigger and press `<Tab>` to expand.

| Trigger | Description                       |
|---------|-----------------------------------|
| `inp`   | Full input file skeleton          |
| `sec`   | Generic section header            |
| `cfa`   | Confirmatory factor analysis      |
| `sem`   | Structural equation model         |
| `lgm`   | Latent growth model               |
| `lca`   | Latent class analysis             |
| `gmm`   | Growth mixture model              |
| `mlm`   | Multilevel (TWOLEVEL) model       |
| `efa`   | Exploratory factor analysis       |
| `mc`    | Monte Carlo simulation            |
| `mi`    | Multiple imputation               |

## License

GPL-3.0
