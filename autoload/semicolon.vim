" vim-semicolon autoload file
" 
" github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.


" ;t - run current test file
" ;tt - run current test
" ;T - run all tests 
"
" fast ipython
" auto workon with tmux
"
"
" how to connect servername with start of debugger reliably 
"
" filetype=qf for tests <enter> goto, <space> run debug 
" filetype=qf for breakppints <enter> goto, <d>remove, and disable, codition


highlight Breakpoint cterm=bold ctermfg=DarkRed ctermbg=None
highlight CurrentDebug cterm=bold ctermfg=23 ctermbg=23
highlight CurrentDebugLine cterm=bold ctermfg=None ctermbg=23

sign define breakpoint text=* texthl=Breakpoint
sign define currentline text=>> linehl=CurrentDebugLine texthl=CurrentDebug

set efm+=break\ %f:%l,break\ %f:%l\\,%m,%-G%.%#

compiler! nose

" initialize variables
let g:semicolon_project_dir = getcwd()
let g:semicolon_tests_dir = getcwd()

let s:base_path = resolve(expand('<sfile>:h') . '/..')
let s:repeater_path = s:base_path . '/scripts/repeater'
let s:vimpdb_path = s:base_path . '/python/vimipdb.py'
let s:nose_debugger_path = s:base_path . '/python/nosedebug.py'

let s:running = 0
let s:current_line_id = 1
let s:next_id = 2
let s:qf_window = ''



" -----------------------------------------------------------------------------
" Publicly accessible functions
" -----------------------------------------------------------------------------

" -----------------------------------------------------------------------------
" Used by plugin on startup
"
func! semicolon#init()
    " Set project and tests based on virtualenv project
    if $VIRTUAL_ENV != '' && $VIRTUALENVWRAPPER_PROJECT_FILENAME != ''
        let fname = $VIRTUAL_ENV .
                    \ '/' . $VIRTUALENVWRAPPER_PROJECT_FILENAME
        let pdir = system('cat ' . fname)[0:-2]

        call semicolon#set_project_dir(pdir)
        call semicolon#set_tests_dir(pdir)
    endif

    " last read and execute .semicolon.vim file if it exists 
    if filereadable('.semicolon.vim')
        source .semicolon.vim
    end

    " set hooks
    autocmd BufRead *.py call s:init_signs()
    autocmd VimLeave,BufDelete *.py call s:update_pdbrc()
    autocmd BufLeave *.py call s:update()
    autocmd VimLeave * call s:exit()
endfunc


" -----------------------------------------------------------------------------
func! semicolon#set_project_dir(...)
    if a:0 == 0
        echo 'Project Dir: ' . g:semicolon_project_dir
    else
        let g:semicolon_project_dir = a:1
    end
endfunc


func! semicolon#set_tests_dir(...)
    if a:0 == 0
        echo 'Tests Dir: ' . g:semicolon_tests_dir
    else
        let g:semicolon_tests_dir = a:1
    end
endfunc


" -----------------------------------------------------------------------------
func! semicolon#quit_debugger()
    if s:running
    	let cmd = 'kill-pane -t ' . s:ipdb_pane
        call s:tmux(cmd)
    endif
endfunc


" -----------------------------------------------------------------------------
func! semicolon#toggle_breakpoint()
    let filename = bufname('%')
    let line_num = line('.')
    let id = s:get_id_at_line(line_num)

    if id == 0
        call s:set_bp(filename, line_num)
    else
        call s:remove_bp(filename, line_num)
    endif
endfunc


" -----------------------------------------------------------------------------
func! semicolon#toggle_breakpoint_list()
    if s:qf_window == 'breakpoints'
        cclose 
        let s:qf_window = ''
    else
        let s:qf_window = 'breakpoints'
        call s:update()
        botright cwindow
    endif
endfunc


" -----------------------------------------------------------------------------
func! semicolon#delete_all_breakpoints()
    " delete all signs
    call s:delete_signs()

    " delete all bp in .pdbrc
    let pdbrc = s:load_pdbrc()

    let k = 0
    for line in pdbrc
        if match(line, 'break \.*') != -1
            if s:running
                let cmd = 'cl ' . matchstr(line, '.*:\d*')[6:]
                call s:send_ipdb(cmd)
            endif

            call remove(pdbrc, k)
        else
            let k = k + 1
        endif
    endfor

    call s:save_pdbrc(pdbrc)
    call s:update_pdbrc_qf()
endfunc


" -----------------------------------------------------------------------------
func! semicolon#delete_file_breakpoints()
    if s:running
        let pdbrc = s:load_pdbrc()

        for line in pdbrc
            if match(line, 'break \.*') != -1
                if match(line, expand('%:s')) != -1
                    let cmd = 'cl ' . matchstr(line, '.*:\d*')[6:]
                    call s:send_ipdb(cmd)
                endif
            endif
        endfor
    endif

    call s:delete_signs(bufname('%'))
    call s:update()
endfunc


" -----------------------------------------------------------------------------
" run with argument
"
func! semicolon#run(...)
    if a:0 == 0
        return 
    endif

    let fname = s:resolve_python_file(a:1)
    if fname == ''
        return
    endif

    let args  = fname . ' ' . join(a:000[1:], ' ')
    call s:run(args, 0)
endfunc


" -----------------------------------------------------------------------------
" run current python file
"
func! semicolon#run_current(cont)
    let fname = expand('%:p')
    call s:run(fname, a:cont)
endfunc


" -----------------------------------------------------------------------------
func! semicolon#debug_location(cont)
    let fname = expand('%:p')
    let test = pylocator#get_location()
    let args = fname . ':' . test
    call s:debug(args, a:cont)
endfunc


" -----------------------------------------------------------------------------
func! semicolon#debug(test)
    let test = split(a:test, ':')

    if len(test) != 2
        echo 'Inalid testname.  Use format module_name:class_name.test_name'
        return
    endif

    let [mname, cname] = test

    let mname = s:resolve_python_file(mname)
    if mname == ''
        return
    endif

    let testname = mname . ':' . cname
    let cmd = 'python ' . s:vimpdb_path . ' -s ' . v:servername . ' '
                \ . '-n ' . testname
                 
    call s:run_debugger(cmd)
endfunc


" -----------------------------------------------------------------------------
func! semicolon#qf_debug(cont)
    if s:qf_window == 'test_results'
        let cl = line('.')
        execute 'cc ' . cl
        call semicolon#debug_location(a:cont)
    endif
endfunc


" -----------------------------------------------------------------------------
func! semicolon#nosetests(...)
    let args = ' ' . join(a:000,' ')

    echom args
    execute 'make! -w ' . g:semicolon_tests_dir . args
    let s:qf_window = 'test_results'
    botright cwindow
endfunc


" -----------------------------------------------------------------------------
" Public method only used from ipdb while it is running
" -----------------------------------------------------------------------------

" -----------------------------------------------------------------------------
func! semicolon#end_debug()
    call s:clear_current_line()
    set cursorline
    let s:running = 0

    execute 'drop ' . s:current_file

    redraw
    redrawstatus

    return ''
endfunc


" -----------------------------------------------------------------------------
func! semicolon#set_current_line(filename, line_num)
    if !filereadable(a:filename)
        return ''
    endif

    call s:clear_current_line()

    " prep file
    execute 'drop ' . a:filename
    set nocursorline

    " set the current line
    execute 'sign place' s:current_line_id 'line=' . a:line_num 
                \ 'name=currentline' 'file=' . a:filename

    " jump to the line
    execute 'normal ' . a:line_num . 'G' 

    " refresh
    redraw
    redrawstatus

    return ''
endfunc


" -----------------------------------------------------------------------------
func! semicolon#center_line(filename)
    if !filereadable(a:filename)
        return ''
    endif

    " center
    execute 'drop ' . a:filename
    execute 'normal zz'

    " refresh
    redraw
    redrawstatus

    return ''
endfunc!


" -----------------------------------------------------------------------------
func! semicolon#set_vim_bp(filename, line_num)
    if empty(getline(a:line_num))
        return ''
    endif

    silent! execute 'sign place ' . s:next_id . ' line=' . a:line_num .
        \' name=breakpoint file=' . bufname(a:filename)

    let s:next_id = s:next_id + 1

    call s:update()

    return ''
endfunc


" -----------------------------------------------------------------------------
func! semicolon#remove_vim_bp(filename, line_num)
    let id = s:get_id_at_line(a:line_num)
    
    silent! execute 'sign unplace ' . id . ' file=' . a:filename

    call s:update()

    return ''
endfun



" -----------------------------------------------------------------------------
" Private functions
" -----------------------------------------------------------------------------

" -----------------------------------------------------------------------------
func! s:run(target, cont)
    let cflag = s:resolve_cont(a:cont)

    windo update

    let cmd = 'python ' . s:vimpdb_path . cflag .
                \ ' -s ' . v:servername . ' ' . a:target
    call s:run_debugger(cmd)
endfunc


" -----------------------------------------------------------------------------
func! s:debug(args, cont)
    let cflag = s:resolve_cont(a:cont)

    windo update

    let cmd = 'python ' . s:vimpdb_path . ' -n ' . cflag .
                \ ' -s ' . v:servername . ' ' . a:args
                 
    call s:run_debugger(cmd)
endfunc


" -----------------------------------------------------------------------------
func! s:resolve_cont(cont)
    if a:cont == 0
        return ''
    else
        return ' -c '
    endif
endfunc



" -----------------------------------------------------------------------------
func! s:clear_current_line()
   execute 'sign unplace' s:current_line_id
endfunc


" -----------------------------------------------------------------------------
func! s:delete_signs(...)
    if a:0 == 0
        let sign_list = s:get_cmd_output('sign place')
    else
        let sign_list = s:get_cmd_output('sign place file=' . a:1)
    endif
        
    let ind = match(sign_list, 'name=breakpoint')
    while ind !=-1
        let id = matchstr(sign_list[ind], 'id=\d\+')[3:]
        execute 'sign unplace ' . id

        let ind = match(sign_list, 'name=breakpoint', ind + 1)
    endwhile

endfunc


" -----------------------------------------------------------------------------
func! s:init_signs()
    let pdbrc = s:load_pdbrc()
    
    " the filename is not relative yet
    let filename = bufname('%')
    let rel_ind = matchend(filename, getcwd())
    let filename = strpart(filename, rel_ind + 1)

    let ind = match(pdbrc, filename)
    while ind != -1
        let line_num = matchstr(pdbrc[ind], ':\d*')[1:]
        call s:set_bp(filename, line_num)
        let ind = match(pdbrc, filename, ind + 1)
    endwhile
endfunc


" -----------------------------------------------------------------------------
func! s:set_bp(filename, line_num)
    if s:running
        call s:set_ipdb_bp(a:filename, a:line_num)
    else
        call semicolon#set_vim_bp(a:filename, a:line_num)
    endif
endfunc


" -----------------------------------------------------------------------------
func! s:remove_bp(filename, line_num)
    if s:running
        call s:remove_ipdb_bp(a:filename, a:line_num)
    else
        call semicolon#remove_vim_bp(a:filename, a:line_num)
    endif
endfunc


" -----------------------------------------------------------------------------
func! s:update()
    call s:update_pdbrc()
    call s:update_pdbrc_qf()
endfunc


" -----------------------------------------------------------------------------
func! s:set_ipdb_bp(filename, line_num)
    let filename = fnamemodify(a:filename, ':p')
    call s:send_ipdb('break ' . filename . ':' . a:line_num)
endfunc


" -----------------------------------------------------------------------------
func! s:remove_ipdb_bp(filename, line_num)
    let filename = fnamemodify(a:filename, ':p')
    call s:send_ipdb('clear ' . filename . ':' . a:line_num)
endfunc


" -----------------------------------------------------------------------------
func! s:send_ipdb(cmd)
    if s:running
        let _cmd = 'send-keys -t ' . s:ipdb_pane .
                    \ ' "' . a:cmd . '" C-m'
        call s:tmux(cmd)
    endif
endfunc


" -----------------------------------------------------------------------------
func! s:update_pdbrc()
    " initialize to all open windows that potentially could have changes
    let cur_win = winnr()
    let files = []
    windo call add(files, expand('%:p'))
    execute cur_win . 'wincmd w'

    let changes = {}
    for file in files
        if !empty(file)
            let changes[file] = []
        endif
    endfor
    
    " build up a changes dictionary
    let sign_list = s:get_cmd_output('sign place')

    for line in sign_list
        " update current file being handled 
        if matchend(line, 'Signs for ') != -1
            let filename = fnamemodify(line[10:-2], ':p') 
            let changes[filename] = []
            continue
        endif

        " ensure it is a breakpoint
        if match(line, 'name=breakpoint') == -1
            continue
        endif
    
        " retrieve a line and add to changes 
        let linenum = matchstr(line, 'line=\d\+')[5:]
        if linenum != -1
            " be sure that linenum exists
            if !empty(getbufline(filename, linenum))
                call add(changes[filename], linenum)
            endif
        endif
    endfor

    " update pdbrc
    let pdbrc = s:load_pdbrc()

    for filename in sort(keys(changes))
        " delete all pdbrc entries with a given filename 
        let ind = match(pdbrc, filename)
        while ind != -1 
            call remove(pdbrc, ind)
            let ind = match(pdbrc, filename, ind)
        endwhile

        " write additions
        for linenum in changes[filename]
            let new_line = 'break ' .  filename . ':' . linenum
            call add(pdbrc, new_line)
        endfor
    endfor

    call s:save_pdbrc(pdbrc)
endfunc


" -----------------------------------------------------------------------------
func! s:get_id_at_line(linenum)
    let sign_list = s:get_cmd_output('sign place buffer=' . winbufnr(0))
    let pattern = 'line=' . a:linenum . '.*name=breakpoint'
    let line_str = matchstr(sign_list, pattern)
    let id_str = matchstr(line_str, 'id=\d\+')
    return str2nr(id_str[3:])
endfunc


" -----------------------------------------------------------------------------
func! s:get_cmd_output(cmd)
    let v:errmsg = ''
    let output   = ''
    let _z       = @z

    try
        redir @z
        silent execute a:cmd

    catch /.*/
        let v:errmsg = substitute(v:exception, '^[^:]\+:', '', '')

    finally
        redir END

        if v:errmsg == ''
          let output = @z
        endif

        let @z = _z
    endtry

    " register holds null for new line
    return split(output, '\%x00')
endfun


" -----------------------------------------------------------------------------
func! s:parse(...)
    if a:0 > 0
        if match(a:1, '.py') != -1
            return [expand(a:1), a:000[1:]]
        endif
    endif

    let fname = expand('%:p')

    if &filetype != 'python'
        redraw
        echo 'Filetype must be .py'
        return []
    endif

    return [fname, a:000]
endfunc


func! s:resolve_python_file(fname)
    " TODO:  Also check with project directory as base
    let fname = expand(a:fname)
    if !filereadable(fname)
        echo 'Python file:' a:fname 'not found.'
        let fname = ''
    endif

    return fname
endfunc


" -----------------------------------------------------------------------------
func! s:exit()
    call semicolon#quit_debugger()
endfunc


" -----------------------------------------------------------------------------
func! s:load_pdbrc()
    let fname = g:semicolon_project_dir . '/.pdbrc'
    if filereadable(fname)
        return readfile(fname)
    else
        return []
    endif
endfunc


" -----------------------------------------------------------------------------
func! s:save_pdbrc(pdbrc)
    let fname = g:semicolon_project_dir . '/.pdbrc'
    if !empty(a:pdbrc)
        call writefile(a:pdbrc, fname)
    else
        call system('rm ' . fname)
    endif
endfunc


" -----------------------------------------------------------------------------
func! s:update_pdbrc_qf()
    if s:qf_window !='breakpoints'
        return
    endif

    let fname = g:semicolon_project_dir . '/.pdbrc'
    if filereadable(fname)
        execute 'cgetfile ' . fname
    else
        call setqflist([])
    endif 

    redraw!
endfunc


" -----------------------------------------------------------------------------
func! s:run_debugger(cmd)
    let cmd = 'cd ' . g:semicolon_project_dir . 
                \ '; ' . s:repeater_path . ' ' . a:cmd 

    if s:running
        call s:tmux('respawn-pane -k -t ' . s:ipdb_pane
                    \ . ' "' . cmd . '"')
        call s:tmux('select-pane -t ' . s:ipdb_pane)

    else
        call s:tmux('split-window -p 25 "' . cmd . '"')

        let s:ipdb_pane = matchstr(system('tmux-pane'), '%\d*')
        let s:running = 1

    endif

    let s:current_file = expand('%:p')
endfunc


" -----------------------------------------------------------------------------
func! s:tmux(cmd)
    if $TMUX != ''
        return system('tmux ' . a:cmd)

    else
        echom "Semicolon must be run from within a tmux session."
        echom "(use 'tmux new vim' to restart vim in a compatible way)"
    endif
endfunc




