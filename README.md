Small Vim plugin for [notes-cli][]
==================================

This is a Vim plugin to use [notes-cli][] more effectively on Vim (Vim8 or later).



## Installation

If you use any package manager, please follow its instruction.

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'rhysd/vim-notes-cli'
```

With [dein.vim](https://github.com/Shougo/dein.vim):

```vim
call dein#add('rhysd/vim-notes-cli')
```

With [minpac](https://github.com/k-takata/minpac):

```vim
call minpac#add('rhysd/vim-notes-cli')
```

When you're using Vim's builtin packager, please follow instruction at `:help pack-add`.

Even if you didn't install [notes-cli][], you don't need to install it. vim-notes-cli automatically
installs `notes` executable and uses it locally.



## Usage

### `:NotesSelect [{args}...]`

It selects one (or multiple) of candidates with [peco][] or [fzf][] and opens selected notes with new Vim buffers.
You can specify a command to select by `g:notes_cli_select_cmd` and how to open buffer by `g:notes_cli_edit_cmd`.

All arguments are passed to `notes list` command. You can specify category and/or tags by `-c` and/or `-t` options.

**Example:** Only targets 'blog' category and 'Go' tag.

```
:NotesSelect -c blog -t Go
```

And you can specify the order of list by `-s`.

**Example:** Sort the list with modified date (default is created date)

```
:NotesSelect -s modified
```


### `:NotesFeelingLucky [{args}...]`

It is similar to `:NotesSelect`, but does not select one from list. It always select the first candidate like
`notes list | head -1`.
This is useful when you want to open the last created/modified note.

**Example:** Open last-modified note

```
:NotesFeelingLucky
```

**Example:** Open last-created note

```
:NotesFeelingLucky -s created
```

`{args}` is passed to `notes list` command.


### `:NotesNew [{category} [{file}]]`

It creates new note with specified category and file name. If they are omitted, it asks them interactively
with prompt.

**Example:** Create 'how-to-open-file.md' with 'memo' category

```
:NotesNew memo how-to-open-file
```


### `:NotesGrep [{args}] /pattern/`

It searches notes with `:vimgrep`. `/pattern/` is passed to first argument of `:vimgrep`. If `{args}` is given,
it is passed to `notes list` to get file paths of notes. By default, `:vimgrep` searches all notes.  Please see
`:help vimgrep` for details of `:vimgrep` command.

**Example:** Search 'open file' in all notes

```
:NotesGrep /open file/
```

**Example:** Search 'open file' in notes tagged with 'Go'

```
:NotesGrep -t Go /open file/
```


### `:NotesList [{args}...]`

It shows list of notes with colors. By default, it outputs the result of `notes --oneline`.

**Example:** Output list of note with one note per line

```
:NotesList
```

**Example:** Output full information of each note (path, metadata, title, body)

```
:NotesList -f
```

### `:Notes {args}...`

It runs `notes` command with `{args}`. Command is run with `:terminal`.

**Example:** Show help of `notes` command

```
:Notes help
```

**Example:** Update `notes` executable

```
:Notes selfupdate
```


## License

[MIT License](LICENSE.txt)

[notes-cli]: https://github.com/rhysd/notes-cli
[peco]: https://github.com/peco/peco
[fzf]: https://github.com/junegunn/fzf
