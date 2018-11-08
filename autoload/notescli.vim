let s:PATH_SEP = has('win32') ? '\' : '/'
function! s:notes_bin() abort
    if exists('g:notes_cli_bin')
        return g:notes_cli_bin
    endif
    if executable('notes')
        return 'notes'
    endif
    " TODO: Download notes binary automatically
    return 'notes'
endfunction

function! s:notes_cmd(args) abort
    let args = map(copy(a:args), 'shellescape(v:val)')
    let out = system(s:notes_bin() . ' ' . join(args, ' '))
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

function! s:on_peco_close(ch) dict abort
    let lines = readfile(self.tmp)
    call delete(self.tmp)

    let home = s:notes_cmd(['config', 'home'])
    if home ==# ''
        return
    endif

    let cmd = get(g:, 'notes_cli_edit_cmd', 'edit!')
    for line in lines
        let s = split(line)
        if s == []
            continue
        endif
        let path = home . s:PATH_SEP . s[0]
        execute cmd path
    endfor
endfunction
function! notescli#select(args) abort
    if exists('g:notes_cli_selector_cmd')
        let selector = g:notes_cli_selector_cmd
    elseif executable('fzf')
        let selector ='fzf'
    elseif executable('peco')
        let selector = 'peco'
    else
        echohl ErrorMsg
        echom '`peco` nor `fzf` is not available. Please set g:notes_cli_selector_cmd'
        echohl None
        return
    endif

    let cmd = [s:notes_bin(), 'list', '--oneline'] + a:args
    let cmd = join(cmd, ' ') . ' | ' . selector
    if has('win32')
        let cmd = ['cmd', '/c', cmd]
    else
        let cmd = ['sh', '-c', cmd]
    endif

    let ctx = {'tmp': tempname()}
    let options = {
        \   'term_name' : 'notes: list | peco',
        \   'term_finish' : 'close',
        \   'out_io' : 'file',
        \   'out_name' : ctx.tmp,
        \   'close_cb' : function('s:on_peco_close', [], ctx),
        \ }
    let ctx.bufnr = term_start(cmd, options)
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
    let out = s:notes_cmd(['new', '--no-inline-input', cat, name, tags])
    if out ==# ''
        return
    endif
    let path = split(out)[-1]
    execute 'edit!' path
    normal! Go
endfunction

function! notescli#open_first_i_am_feeling_lucky(args) abort
    let args = a:args
    if args == []
        " Open the last modified note by default
        let args = ['--sort', 'modified']
    endif
    let out = s:notes_cmd(['list'] + args)
    if out ==# ''
        return
    endif
    let first = split(out)[0]
    execute 'edit!' first
endfunction

function! notescli#list(args) abort
    let args = join(a:args, ' ')
    let cmdline = 'terminal ' . s:notes_bin() . ' list --oneline'
    if args !=# ''
        let cmdline .= ' ' . args
    endif
    execute cmdline
endfunction

function notescli#grep(pat) abort
    let home = s:notes_cmd(['config', 'home'])
    if home ==# ''
        return
    endif
    let glob = home . s:PATH_SEP . '*' . s:PATH_SEP . '*.md'
    execute 'vimgrep' a:pat glob
endfunction

function! notescli#notes(args_str) abort
    let cmdline = 'terminal ' . s:notes_bin()
    if a:args_str !=# ''
        let cmdline .= ' ' . a:args_str
    endif
    execute cmdline
endfunction
