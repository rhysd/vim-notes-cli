let s:PATH_SEP = has('win32') ? '\' : '/'
let s:REPO_ROOT = fnamemodify(expand('<sfile>'), ':p:h:h')

function! s:echoerr(msg) abort
    echohl ErrorMsg
    echom a:msg
    echohl None
endfunction

function! s:local_bin() abort
    let dir = get(g:, 'notes_cli_download_dir', s:REPO_ROOT)

    let binpath = dir . s:PATH_SEP . 'notes'
    if has('win32')
        let binpath .= '.exe'
    endif

    if filereadable(binpath)
        return binpath
    endif

    if exists('g:notes_cli_platform_name')
        let platform = g:notes_cli_platform_name
    elseif has('win32')
        let platform = 'windows'
    elseif has('mac')
        let platform = 'darwin'
    elseif has('unix')
        let platform = 'linux'
    else
        call s:echoerr('Unknown platform. Please set g:notes_cli_platform_name')
        return ''
    endif

    let suffix = '.zip'
    if has('win32')
        let suffix = '.exe' . suffix
    endif
    let archive = 'notes_' . platform . '_amd64' . suffix
    let zippath = dir . s:PATH_SEP . archive

    if !executable('curl')
        call s:echoerr('`curl` command is necessary to download binary')
        return ''
    endif

    if !executable('unzip')
        call s:echoerr('`unzip` command is necessary to unzip downloaded archive')
        return ''
    endif

    let out = system("curl -Ls -o /dev/null -w '%{url_effective}' https://github.com/rhysd/notes-cli/releases/latest")
    if v:shell_error
        call s:echoerr('Cannot get redurect URL: ' . out)
        return ''
    endif
    let tag = split(out, '/')[-1]

    let url = printf('https://github.com/rhysd/notes-cli/releases/download/%s/%s', tag, archive)
    echom 'Downloading and unarchiving the latest executable from ' . url . ' to ' . dir

    let curl_cmd = printf('curl -L -o %s %s 2>&1', shellescape(zippath), shellescape(url))
    let unzip_cmd = printf('unzip %s -d %s', shellescape(zippath), shellescape(dir))
    let out = system(curl_cmd . ' && ' . unzip_cmd)
    if v:shell_error
        call s:echoerr('Downloading with curl and unarchiving with unzip failed: ' . out)
        return ''
    endif

    " verify
    if !filereadable(binpath)
        call s:echoerr('Executable was not downloaded successfully. Please check following directory and set g:notes_cli_bin manually: ' . dir)
        return ''
    endif

    call delete(zippath)

    return binpath
endfunction

function! s:notes_bin() abort
    if exists('g:notes_cli_bin')
        return g:notes_cli_bin
    endif

    if executable('notes')
        let g:notes_cli_bin = 'notes'
        return g:notes_cli_bin
    endif

    let bin = s:local_bin()
    if bin !=# ''
        let g:notes_cli_bin = bin
        return g:notes_cli_bin
    endif

    return ''
endfunction

function! s:notes_cmd(args) abort
    let bin = s:notes_bin()
    if bin ==# ''
        return ''
    endif
    let args = map(copy(a:args), 'shellescape(v:val)')
    let out = system(bin . ' --no-color ' . join(args, ' '))
    if v:shell_error
        call s:echoerr(out)
        return ''
    endif
    if out =~# '\n$'
        let out = out[:-2]
    endif
    return out
endfunction

function! s:completion(subcmd, lead) abort
    let args = ['help']
    if a:subcmd !=# ''
        let args += [a:subcmd]
    endif

    let lines = split(s:notes_cmd(args), '\n')
    if empty(lines)
        return []
    endif

    if a:subcmd ==# ''
        let idx = index(lines, 'Commands:')
        if idx == -1
            return []
        endif
        let ret = []
        for l in lines[idx+1:]
            let cmd = matchstr(l, '^  \zs\h\w*\ze\>')
            if cmd ==# ''
                continue
            endif
            let ret += [cmd]
        endfor
        if ret != [] && a:lead !=# ''
            call filter(ret, 'v:val =~# ''^' . a:lead . "'")
        endif
        return ret
    endif

    let idx = index(lines, 'Flags:')
    if idx == -1
        return []
    endif
    let ret = []
    for l in lines[idx+1:]
        let cmds = matchstr(l, '^\s\+\zs-\h, --\h[[:alnum:]-]\+')
        if cmds !=# ''
            let ret += split(cmds, ',\s\+')
            continue
        endif
        let cmd = matchstr(l, '^\s\+\zs--\h[[:alnum:]-]\+')
        if cmd !=# ''
            let ret += [cmd]
            continue
        endif
    endfor
    if ret != [] && a:lead !=# ''
        call filter(ret, 'v:val =~# ''^' . a:lead . "'")
    endif
    return ret
endfunction

function! notescli#c_list(lead, cmdline, col) abort
    return s:completion('list', a:lead)
endfunction
function! s:on_selector_close(ch) dict abort
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
    if !exists('g:notes_cli_selector_cmd')
        if executable('fzf')
            let g:notes_cli_selector_cmd ='fzf'
        elseif executable('peco')
            let g:notes_cli_selector_cmd ='peco'
        else
            call s:echoerr('`peco` nor `fzf` is not available. Please set g:notes_cli_selector_cmd')
            return
        endif
    endif

    let bin = s:notes_bin()
    if bin ==# ''
        return
    endif
    let cmd = [bin, 'list', '--oneline'] + a:args
    let cmd = join(cmd, ' ') . ' | ' . g:notes_cli_selector_cmd
    if has('win32')
        let cmd = ['cmd', '/c', cmd]
    else
        let cmd = ['sh', '-c', cmd]
    endif

    let ctx = {'tmp': tempname()}
    let options = {
        \   'term_name' : 'notes: list | ' . g:notes_cli_selector_cmd,
        \   'term_finish' : 'close',
        \   'out_io' : 'file',
        \   'out_name' : ctx.tmp,
        \   'close_cb' : function('s:on_selector_close', [], ctx),
        \ }
    let ctx.bufnr = term_start(cmd, options)
endfunction

function! notescli#c_new(lead, cmdline, col) abort
    return s:completion('new', a:lead)
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

if has('win32')
    function! s:is_absolute(path) abort
        return a:path =~# '^[a-zA-Z]:[/\\]'
    endfunction
else
    function! s:is_absolute(path) abort
        return a:path[0] ==# '/'
    endfunction
endif

function! s:open_notes_under_cursor() abort
    let fields = split(getline('.'), '\s\+')
    if len(fields) == 0
        echo 'No list item found under cursor'
        return
    endif

    let path = fields[0]
    if !s:is_absolute(path)
        let home = s:notes_cmd(['config', 'home'])
        if home ==# ''
            return
        endif
        let path = home . s:PATH_SEP . path
    endif

    if !filereadable(path)
        call s:echoerr('File does not exist: ' . path)
        return
    endif

    let cmd = get(g:, 'notes_cli_edit_cmd', 'edit!')
    execute cmd path
endfunction

function! notescli#list(args) abort
    let bin = s:notes_bin()
    if bin ==# ''
        return
    endif
    let args = join(a:args, ' ')
    let cmdline = 'terminal ' . bin . ' list --oneline'
    if args !=# ''
        let cmdline .= ' ' . args
    endif
    execute cmdline
    nnoremap <buffer><CR> :<C-u>call <SID>open_notes_under_cursor()<CR>
endfunction

function! notescli#c_grep(lead, cmdline, col) abort
     " Omit 'NotesGrep ' by 10:
    let args = a:cmdline[10 : a:col]
    if args =~# '\s\+/'
        return []
    endif
    return filter(s:completion('list', a:lead), 'v:val =~# ''^-c\|--category\|-t\|--tag$''')
endfunction
function notescli#grep(args_str) abort
    let idx = match(a:args_str, '\s\+\ze/[^/]*/')
    if idx <= 0
        let pathlist = s:notes_cmd(['list'])
        let pat = a:args_str
    else
        let pathlist = s:notes_cmd(['list'] + split(a:args_str[:idx], '\s\+'))
        let pat = a:args_str[idx:]
    endif

    if empty(pathlist)
        echo 'No note was found'
        return
    endif

    execute 'vimgrep' pat substitute(pathlist, '\n', ' ', 'g')

    if get(g:, 'notes_cli_open_quickfix_on_grep', 1) && len(getqflist()) > 1
        copen
    endif
endfunction

function! notescli#c_notes(lead, cmdline, col) abort
     " Omit 'Notes ' by 6:
    let args = split(a:cmdline[6 : a:col])
    let l = len(args)
    if l == 0 || (l == 1 && a:lead !=# '')
        return s:completion('', a:lead)
    endif
    return s:completion(args[0], a:lead)
endfunction
function! notescli#notes(args_str) abort
    let bin = s:notes_bin()
    if bin ==# ''
        return
    endif
    let cmdline = 'terminal ' . bin
    if a:args_str !=# ''
        let cmdline .= ' ' . a:args_str
    endif
    execute cmdline
endfunction
