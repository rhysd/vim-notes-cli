function! s:notes_cmd(...) abort
    let args = map(copy(a:000), 'shellescape(v:val)')
    let out = system(g:notes_cli_bin . ' ' . join(args, ' '))
    if v:shell_error
        echohl ErrorMsg
        echom out
        echohl None
        return ''
    endif
    if out =~# '\n$'
        let out = out[:-2]
    endif
    return out
endfunction

function! s:notes_selection_done(selected) abort
    silent! autocmd! plugin-notes-cli
    let home = s:notes_cmd('config', 'home')
    if home ==# ''
        return
    endif
    let sep = has('win32') ? '\' : '/'
    let path = home . sep . split(a:selected, ' ')[0]
    execute 'split' '+setf\ markdown' path
    echom 'Note opened: ' . a:selected
endfunction
function! notescli#open(args) abort
    execute 'terminal ++close bash -c "notes list --oneline | peco"'
    augroup plugin-notes-cli
        autocmd!
        autocmd BufWinLeave <buffer> call <SID>notes_selection_done(getline(1))
    augroup END
endfunction

function! notescli#new(...) abort
    if has_key(a:, 1)
        let cat = a:1
    else
        let cat = input('category?: ')
    endif
    if has_key(a:, 2)
        let name = a:2
    else
        let name = input('filename?: ')
    endif
    let tags = get(a:, 3, '')
    let out = s:notes_cmd('new', '--no-inline-input', cat, name, tags)
    if out == ''
        return
    endif
    let path = split(out)[-1]
    execute 'edit!' path
    normal! Go
endfunction

function! notescli#last_mod(args) abort
    let out = system('notes list --sort modified ' . a:args)
    if v:shell_error
        echohl ErrorMsg | echomsg string(cmd) . ' failed: ' . out | echohl None
        return
    endif
    let last = split(out)[0]
    execute 'edit!' last
endfunction
