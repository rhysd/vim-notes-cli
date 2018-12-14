if (exists('g:loaded_notes_cli') && g:loaded_notes_cli) || &cp
    finish
endif

command! -nargs=* -complete=customlist,notescli#c_notes Notes call notescli#notes(<q-args>)
command! -nargs=* -complete=customlist,notescli#c_list NotesSelect call notescli#select([<f-args>])
command! -nargs=* -complete=customlist,notescli#c_new NotesNew call notescli#new(<f-args>)
command! -nargs=* -complete=customlist,notescli#c_list NotesFeelingLucky call notescli#open_first_i_am_feeling_lucky([<f-args>])
command! -nargs=* -complete=customlist,notescli#c_list NotesList call notescli#list([<f-args>])
command! -nargs=* -complete=customlist,notescli#c_grep NotesGrep call notescli#grep(<q-args>)

let g:loaded_notes_cli = 1
