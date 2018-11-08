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
        return 'notes'
    endif
    return s:local_bin()
endfunction

function! s:notes_cmd(args) abort
    let bin = s:notes_bin()
    if bin ==# ''
        return
    endif
    let args = map(copy(a:args), 'shellescape(v:val)')
    let out = system(bin . ' ' . join(args, ' '))
    if v:shell_error
        call s:echoerr(out)
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
        call s:echoerr('`peco` nor `fzf` is not available. Please set g:notes_cli_selector_cmd')
        return
    endif

    let bin = s:notes_bin()
    if bin ==# ''
        return
    endif
    let cmd = [bin, 'list', '--oneline'] + a:args
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
