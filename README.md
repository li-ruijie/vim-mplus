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
written by different people, or pasted from different sources, can look
inconsistent. The `gq` formatter normalises a selection (or the whole file
with `gggqG`) into a canonical style:

- **Uppercase all code** — Mplus convention. Quoted strings and file names
  keep their spelling.
- **Expand abbreviations** — e.g. `ANAL:` → `ANALYSIS:`, `ESTI =` →
  `ESTIMATOR =`. Only unambiguous 4+ character abbreviations are expanded,
  and only where Mplus reads a keyword: section headers, the option name
  that starts a statement, and the `OUTPUT` list. Variable names are left
  alone, so `CLUSTER = clus;` does not become `CLUSTER = CLUSTER;`.
- **Split section headers** — `DATA: FILE = ex.dat;` becomes two lines
  (`DATA:` on its own line, body indented below) so each section is delimited
  and folds correctly.
- **Replace `IS`/`ARE` with `=`** after an option name — all three are
  interchangeable in Mplus; `=` is shorter and more common.
- **Normalise whitespace** — tabs → 4 spaces, trailing whitespace removed.
- **Re-indent** — section headers at column 0, body at one `shiftwidth`.

TITLE sections and comments are left alone (whitespace cleanup only).
The formatter also sets `fileformat=unix` and `fileencoding=utf-8` to avoid
encoding issues across platforms.

### File type detection

Other programs also use the `.inp` and `.out` extensions, so the plugin
reads the file before it sets a filetype:

- A new or blank `.inp` file is `mplus-inp`. A `.inp` file with content is
  `mplus-inp` when its first line of code is an Mplus command header such as
  `TITLE:`, `anal:`, or `MODEL INDIRECT:`. Comments and blank lines above the
  header are allowed.
- A `.out` file is `mplus-out` when it starts as Mplus output does, with the
  lines `Mplus VERSION ...` and `MUTHEN & MUTHEN`.
- A filetype that another plugin has already set is kept.

For any other file, run `:setfiletype mplus-inp` or `:setfiletype mplus-out`.

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

AGPL-3.0
