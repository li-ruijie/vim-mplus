# vim-mplus

Vim plugin for [Mplus](https://www.statmodel.com/) statistical software files (`.inp` and `.out`).

## Features

- Syntax highlighting for keywords, commands, model operators, section headers, and comments
- Syntax-based folding for input sections and output blocks
- Indentation (section headers at column 0, body indented)
- Omni-completion (`<C-x><C-o>`) for all Mplus keywords via `syntaxcomplete`
- [UltiSnips](https://github.com/SirVer/ultisnips) snippets for common analyses (CFA, SEM, LGM, LCA, and more)

### Formatter (`gq`)

Mplus is case-insensitive and allows keywords to be abbreviated to four or
more characters, `IS`/`ARE` to be used in place of `=`, and section headers
to share a line with their content. This flexibility means input files
written by different people—or pasted from different sources—can look wildly
inconsistent. The `gq` formatter normalises a selection (or the whole file
with `gggqG`) into a canonical style:

- **Uppercase all code** — Mplus convention; makes keywords stand out from
  variable names.
- **Expand abbreviations** — e.g. `ANAL:` → `ANALYSIS:`, `ESTI` →
  `ESTIMATOR`. Only unambiguous 4+ character abbreviations are expanded.
- **Split section headers** — `DATA: FILE = ex.dat;` becomes two lines
  (`DATA:` on its own line, body indented below) so each section is clearly
  delimited and folds correctly.
- **Replace `IS`/`ARE` with `=`** — all three are interchangeable in Mplus;
  `=` is shorter and more common.
- **Normalise whitespace** — tabs → 4 spaces, trailing whitespace removed.
- **Re-indent** — section headers at column 0, body at one `shiftwidth`.

TITLE sections and comments are left alone (whitespace cleanup only).
The formatter also sets `fileformat=unix` and `fileencoding=utf-8` to avoid
encoding issues across platforms.

## Installation

[vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'li-ruijie/vim-mplus'
```

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ 'li-ruijie/vim-mplus', ft = { 'mplus-inp', 'mplus-out' } }
```

Or copy the contents to your Vim runtime directory.

## Commands

| Command | Description                                  |
|---------|----------------------------------------------|
| `:Mout` | Open corresponding `.out` file in vertical split |
| `:Mrun` | Run Mplus on current file (Windows/Linux)    |

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
