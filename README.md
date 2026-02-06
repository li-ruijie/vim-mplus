# vim-mplus

Vim plugin providing syntax highlighting for [Mplus](https://www.statmodel.com/) statistical software files.

## Features

- Syntax highlighting for `.inp` (input) and `.out` (output) files
- Highlights keywords, commands, model operators, section headers, and comments
- Commands for running Mplus and viewing output

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

## License

GPL-3.0
