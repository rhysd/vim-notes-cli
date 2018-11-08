if (exists('g:loaded_notes_cli') && g:loaded_notes_cli) || &cp
    finish
endif

let g:notes_cli_bin = get(g:, 'notes_cli_bin', 'notes)

command! -nargs=* NotesOpen call notescli#open(<q-args>)
command! -nargs=* NotesNew call notescli#new(<f-args>)
command! -nargs=* NotesLastMod call notescli#last_mod(<q-args>)

let g:loaded_notes_cli = 1
