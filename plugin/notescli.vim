if (exists('g:loaded_notes_cli') && g:loaded_notes_cli) || &cp
    finish
endif

let g:notes_cli_bin = get(g:, 'notes_cli_bin', 'notes')

command! -nargs=+ Notes call notescli#notes(<q-args>)
command! -nargs=* NotesSelect call notescli#select([<f-args>])
command! -nargs=* NotesNew call notescli#new(<f-args>)
command! -nargs=* NotesFeelingLucky call notescli#open_first_i_am_feeling_lucky([<f-args>])
command! -nargs=* NotesList call notescli#list([<f-args>])
command! -nargs=+ NotesGrep call notescli#grep(<q-args>)

let g:loaded_notes_cli = 1
