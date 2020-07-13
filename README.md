# blameline.vim

Fork of [blamer.nvim](https://github.com/APZelos/blamer.nvim) that adds
async calls to git. Both projects are inspired by the VS Code GitLens plugin.

This fork breaks support for neovim, windows, blaming entire visual blocks,
relative timestamps, and probably some more. Replaces the timer/delay with
async calls.

Requires Vim8 for popup support.


## Installation

#### vim-plug

```
Plug 'adamatom/blameline.vim'
```

## Configuration

#### Enabled

Enables blameline on vim startup.

You can toggle blameline on/off with the `:BlamelineToggle` command.

If the current directory is not a git repository the blameline will be automatically disabled.

Default: `0`

```
let g:blameline_enabled = 1
```

#### Prefix

The prefix that will be added to the template.

Default: `' '`

```
let g:blameline_prefix = ' > '
```

#### Template

The template for the blame message that will be shown.

Default: `'<author>, <author-time> • <summary>'`

Available options: `<author>`, `<author-mail>`, `<author-time>`, `<committer>`, `<committer-mail>`, `<committer-time>`, `<summary>`, `<commit-short>`, `<commit-long>`.

```
let g:blameline_template = '<committer> <summary>'
```

### Date format

The [format](https://devhints.io/datetime#strftime-format) of the date fields. (`<author-time>`, `<committer-time>`)

Default: `'%m/%d/%y %H:%M'`

```
let g:blameline_date_format = '%d/%m/%y'
```

#### Highlight

The color of the blame message.

Default: `link Blameline Comment`

```
highlight Blameline guifg=lightgrey
```

## License

This software is released under the MIT License.
