" vim-semicolon
" 
" https://github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.


"
" toggle bp off with running ipdb
" clear all bp with running ipdb
"
" only allow breakpoints for python filetype
" clear all breakpoint - cl
" clear breaks by number

" leaves the buffer in a different state at end - preserve it somehow to the
" original file that was present in the window when it started debugging
"
" mismatch with file names in .pdbrc
" 
" how to connect servername with start of debugger reliably 
"
" find current class and function:  http://jeetworks.org/node/147
"
" filetype=qf for tests <enter> goto, <space> run debug 
" filetype=qf for breakppints <enter> goto, <d>remove, and disable, codition
"
"
" tests:
" ;d - for debugging current file
" ;dd - debug current test
" ;D - debug specific file with parameters
"
"
" ;t - run current test file
" ;tt - run current test
" ;T - run all tests 



let s:python_path = expand('<sfile>:h') . '/../python'

" -----------------------------------------------------------------------------
func! semicolon#init()
    highlight Breakpoint cterm=bold ctermfg=red ctermbg=None

    sign define breakpoint text=* texthl=Breakpoint
    sign define currentline text=-> linehl=Visual texthl=Visual

    set efm=break\ %f:%l,break\ %f:%l\\,%m,%-G%.%#

    let s:running = 0
    let s:current_line_id = 1
    let s:next_id = 2
    let s:breakpoint_list = 0


    " Set project based on virtualenv project
    if $VIRTUAL_ENV != '' && $VIRTUALENVWRAPPER_PROJECT_FILENAME != ''
        let fname = $VIRTUAL_ENV .
                    \ '/' . $VIRTUALENVWRAPPER_PROJECT_FILENAME
        let pdir = system('cat ' . fname)[0:-2]
    else
        let pdir = getcwd()
    endif

    call semicolon#set_project(pdir)

    autocmd BufRead *.py call s:init_signs()
    autocmd VimLeave,BufDelete *.py call s:update_pdbrc()
    autocmd BufLeave *.py call s:update()
    autocmd VimLeave * call s:exit()
endfunc


" -----------------------------------------------------------------------------
func! semicolon#set_project(...)
    if a:0 == 0
        echo 'Project Dir: ' . s:project_dir
    else
        let s:project_dir = a:1
    end
endfunc


" -----------------------------------------------------------------------------
func! semicolon#quit_debugger()
    if s:running
    	let cmd = 'tmux kill-pane -t ' . s:ipdb_pane
    	call system(cmd)
    endif
    call semicolon#end_debug()
endfunc


" -----------------------------------------------------------------------------
func! semicolon#toggle_breakpoint()
    let filename = bufname('%')
    let line_num = line('.')
    let id = s:get_id_at_line(line_num)

    if id == 0
        call s:set_bp(filename, line_num)
    else
        call s:remove_bp(filename, id)
    endif
endfunc


" -----------------------------------------------------------------------------
func! semicolon#toggle_breakpoint_list()
    if s:breakpoint_list
        cclose 
        let s:breakpoint_list = 0
    else
        call s:update()
        botright copen
        let s:breakpoint_list = 1
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
    call s:delete_signs(bufname('%'))
    call s:update()
endfunc


" -----------------------------------------------------------------------------
func! semicolon#end_debug()
    call s:clear_current_line()
    set cursorline
    let s:running = 0

    return ''
endfunc


" -----------------------------------------------------------------------------
func! semicolon#set_current_line(filename, line_num)
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
    call semicolon#set_vim_bp(a:filename, a:line_num)

    if s:running
        call s:set_ipdb_bp(a:filename, a:line_num)
    endif
endfunc


" -----------------------------------------------------------------------------
func! s:remove_bp(filename, line_num)
    call semicolon#remove_vim_bp(a:filename, a:line_num)

    if s:running
        call s:remove_ipdb_bp(a:filename, a:line_num)
    endif
endfunc


" -----------------------------------------------------------------------------
func! semicolon#set_vim_bp(filename, line_num)
    if empty(getline(a:line_num))
        return ''
    endif

    silent! execute 'sign place ' . s:next_id . ' line=' . a:line_num .
        \' name=breakpoint file=' . a:filename

    let s:next_id = s:next_id + 1

    call s:update()

    return ''
endfunc


" -----------------------------------------------------------------------------
func! semicolon#remove_vim_bp(filename, id)
    silent! execute 'sign unplace ' . a:id . ' file=' . a:filename

    call s:update()

    return ''
endfun


" -----------------------------------------------------------------------------
func! s:update()
    call s:update_pdbrc()
    call s:update_pdbrc_qf()
endfunc


" -----------------------------------------------------------------------------
func! s:set_ipdb_bp(filename, line_num)
    call s:send_ipdb('break ' . a:filename . ':' . a:line_num)
endfunc


" -----------------------------------------------------------------------------
func! s:remove_ipdb_bp(filename, line_num)
    call s:send_ipdb('clear ' . a:filename . ':' . a:line_num)
endfunc


" -----------------------------------------------------------------------------
func! s:send_ipdb(cmd)
    if s:running
        let tmux_cmd = 'tmux send-keys -t ' . s:ipdb_pane .
                    \ ' "' . a:cmd . '" C-m'
        call system(tmux_cmd)
    endif
endfunc


" -----------------------------------------------------------------------------
func! s:update_pdbrc()
    " initialize to all open windows that potentially could have changes
    let cur_win = winnr()
    let files = []
    windo call add(files, @%)   
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
            let filename = line[10:-2] 
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



"------------------------------------------------------------------------------
"func! semicolon#toggle_console()
"    if !s:console_visible
"        call semicolon#open_console()
"    "else
"    "    " possibly mannually closed if they are both invalid
"    "    if !s:is_pane_valid(g:semicolon_debug_pane_id) &&
"    "                \ !s:is_pane_valid(g:semicolon_ipython_pane_id)
"    "        let g:semicolon_console_visible = 0
"    "        call semicolon#open_console()
"    "    else
"    "        call semicolon#close_console()
"    "    endif
"    endif
"endfunc


"func! semicolon#open_console()
"    "if !s:check_tmux()
"    "    return
"    "endif
"
"    if s:console_visible
"        return
"    endif
"
"    call s:init_console()
"
"    call system('tmux join-pane -l 20 -d -s ' . g:semicolon_debug_pane_id)
"    call system('tmux join-pane -h -d' .
"                \ ' -t ' . g:semicolon_debug_pane_id .
"                \ ' -s ' . g:semicolon_ipython_pane_id)
"
"    let g:semicolon_console_visible = 1
"endfunc


"func! semicolon#close_console()
"    if !s:check_tmux()
"        return
"    endif
"
"    if !g:semicolon_console_visible
"        return
"    endif
"
"    call s:check_console()
"
"    call system('tmux join-pane -d -p 80' .
"                \ ' -s ' . g:semicolon_debug_pane_id .
"                \ ' -t ' . g:semicolon_terminal_pane_id)
"
"    call system('tmux join-pane -h -d ' .
"                \ ' -s ' . g:semicolon_ipython_pane_id .
"                \ ' -t ' . g:semicolon_debug_pane_id)
"
"    let g:semicolon_console_visible = 0
"endfunc


"func! semicolon#select_ipython()
"    if !s:check_tmux()
"        return
"    endif
"
"    call semicolon#open_console()
"    call system('tmux select-pane -t ' . g:semicolon_ipython_pane_id)
"endfunc
"
"
"func! semicolon#restart_ipython()
"    if !s:check_tmux()
"        return
"    endif
"
"    call s:respawn_ipython()
"    call semicolon#select_ipython()
"endfunc


"------------------------------------------------------------------------------

" run current file if no .py is given.
func! semicolon#run(...)
    let res = call('s:parse', a:000)
    if len(res) == 0
        return
    endif

    let fname = res[0]
    let args = res[1]

    windo update
    
    let vimpdb = s:python_path . '/vimpdb.py'
    let target = v:servername
    
    let cmd = 'cd ' . s:project_dir . '; python ' . vimpdb . ' ' . target .
                \ ' ' . fname . ' ' . join(args, ' ') 

    if s:running
        call system('tmux respawn-pane -k -t ' . s:ipdb_pane . ' "' . cmd . '"')
        call system('tmux select-pane -t ' . s:ipdb_pane)
    else
        call system('tmux split-window -p 25 "' . cmd . '"')
        let s:ipdb_pane = matchstr(system('tmux-pane'),'%\d*')
        let s:running = 1
    endif
endfunc


" prompt for arguments to run
func! semicolon#run_args_prompt()
    let fname = expand('%') 
    let args = input('ipdb ' . fname . ' ', '', 'file')
    call call('semicolon#run', insert(split(args, '\ '), fname))
endfunc


" prompt for filename and arguments to run
func! semicolon#run_prompt()
    let args = input('ipdb ', '', 'file')
    call call('semicolon#run', split(args, '\ '))
endfunc


"" debug the current test file if no arguments are given
"func! semicolon#debug_test(...)
"    let res = call('s:parse', a:000)
"    let fname = res[0]
"    let args = res[1]
"
"    update
"    let cmd = 'nosetests ' . fname . ' ' . join(args, ' ') 
"    call s:send_debug_cmd(cmd)
"endfunc
"
"
"" run the test given in the current file. if no args then run all tests in file
"func! semicolon#run_test(...)
"    let cmd = 'make!'
"    let cmd .= expand('%')
"    if a:0 > 0
"        if len(a:1) > 0
"            let cmd .= ':' . a:1
"        endif
"    endif
"    execute cmd
"    cwindow
"endfunc
"
"
"" run all tests
"func! semicolon#run_all_tests()
"    make! 
"    cwindow
"endfunc
"
"
"" prompt for the name of a test in the current file to run
"func! semicolon#run_test_prompt()
"    let test = input('test name: ', '', 'file')
"    call semicolon#run_test(test)
"endfunc


"func! semicolon#quit()
"    if exists('g:semicolon_terminal_pane_id') &&
"                \ s:is_pane_valid(g:semicolon_ipython_pane_id)
"        call system('tmux kill-pane -t ' . g:semicolon_terminal_pane_id)
"    endif
"
"    if exists('g:semicolon_debug_pane_id') &&
"                \ s:is_pane_valid(g:semicolon_debug_pane_id)
"        call system('tmux kill-pane -t ' . g:semicolon_debug_pane_id)
"    endif
"
"    if exists('g:semicolon_ipython_pane_id') &&
"                \ s:is_pane_valid(g:semicolon_ipython_pane_id)
"        call system('tmux kill-pane -t ' . g:semicolon_ipython_pane_id)
"    endif
"
"    call system('tmux setw -u -t semicolon remain-on-exit')
"    call system('tmux kill-window -t console')
"
"    let shell_name = split($SHELL, '/')[-1]
"    call system('tmux rename-window ' . shell_name)
"    silent !echo -en "\033]2;$HOSTNAME\\007"
"endfunc


"------------------------------------------------------------------------------
func! s:check_tmux()
    if s:tmux_running
        echo "Semicolon must be run within a tmux session.
            \ (Use 'tmux new vim' to start one.)"
    endif

    return s:tmux_running
endfunc


"func! s:init_console()
"    call s:check_debug()
"    call s:check_ipython()
"endfunc


"func! s:check_debug()
"    if exists('g:semicolon_debug_pane_id') &&
"                \ s:is_pane_valid(g:semicolon_debug_pane_id)
"        return
"    endif
"
"    call s:make_debug()
"endfunc
"
"
"func! s:check_ipython()
"    if exists('g:semicolon_ipython_pane_id') &&
"                \ s:is_pane_valid(g:semicolon_ipython_pane_id)
"        return
"    endif
"
"    call s:make_ipython()
"endfunc
"
"
"func! s:make_console()
"    let res = system('tmux list-windows')
"    if match(res, 'console') == -1
"        call system('tmux new-window -d -n console')
"        call system('tmux setw -t console remain-on-exit')
"        call system('tmux setw -u -t console monitor-activity')
"
"        call s:stamp_pane('console', 'terminal')
"        call s:set_virtualenv('console')
"        call s:clear_pane('console')
"        let g:semicolon_terminal_pane_id = s:get_last_pane_id('console')
"    endif
"endfunc
"
"
"func! s:make_debug()
"    call system('tmux split-window -d -t ' .
"                \ g:semicolon_terminal_pane_id . ' -p 80')
"    let g:semicolon_debug_pane_id = s:get_last_pane_id('console')
"
"    call s:respawn_debug()
"endfunc
"
"
"func! s:make_ipython()
"    call system('tmux split-window -h -d -t ' . g:semicolon_debug_pane_id)
"    let g:semicolon_ipython_pane_id = s:get_last_pane_id('console')
"
"    call s:respawn_ipython()
"endfunc
"
"
"func! s:respawn_debug(...)
"    call s:init_console()
"
"    call system('tmux clear-history -t' . g:semicolon_debug_pane_id)
"        
"    if a:0 == 0
"        let full_cmd = s:base_dir . 'spawn_debug -x'
"        call system('tmux respawn-pane -k -t ' . g:semicolon_debug_pane_id
"                \ . ' "' . full_cmd . '"')
"
"        return
"    else
"        let cmd = a:1
"    endif
"
"    let full_cmd = s:base_dir . 'spawn_debug'
"    
"    if $VIRTUAL_ENV != ''
"        let full_cmd .= ' -v ' . $VIRTUAL_ENV
"    endif
"
"    if g:semicolon_console_visible
"        let full_cmd .= ' ' . '-o'
"    endif
"
"    let full_cmd .= ' ' . $TMUX_PANE . ' ' . cmd 
"
"    call system('tmux respawn-pane -k -t ' . g:semicolon_debug_pane_id
"                \ . ' "' . full_cmd . '"')
"endfunc
"
"
"func! s:respawn_ipython()
"    if $VIRTUAL_ENV != ''
"        let full_cmd = s:base_dir . 'spawn_ipython -v ' . $VIRTUAL_ENV .
"                    \ ' ' . $TMUX_PANE
"    else
"        let full_cmd = s:base_dir . 'spawn_ipython ' . $TMUX_PANE 
"    endif
"
"    call system('tmux respawn-pane -k -t ' . g:semicolon_ipython_pane_id
"                \ . ' "' . full_cmd . '"')
"endfunc
"
"
"func! s:is_pane_valid(pane)
"    return match(system('tmux list-panes -a'), a:pane) != -1
"endfunc
"
"
"func! s:get_last_window_id()
"    let res = system('tmux list-windows -F "#{window_index}"')
"    return split(res)[-1]
"endfunc
"
"
"func! s:get_last_pane_id(window)
"    let res = system('tmux list-panes -t ' . a:window . ' -F "#{pane_id}"')
"    
"    let vals = split(res)
"    return sort(vals)[-1]
"endfunc
"
"
"func! s:send_keys(pane, cmd)
"    call system('tmux send-keys -t ' . a:pane . ' "' . a:cmd . '" C-m')
"endfunc
"
"
"func! s:send_debug_cmd(cmd)
"    call s:respawn_debug(a:cmd)
"    call semicolon#open_console()
"    call s:select_debug()
"endfunc
"
"
"func! s:stamp_pane(pane, name)
"    let cmd = "echo -en '\\033]2;" . a:name . "\\033\\'"
"    call s:send_keys(a:pane, cmd)
"endfunc
"
"
"func! s:set_virtualenv(pane)
"    call s:send_keys(a:pane, 'source ' . $VIRTUAL_ENV . '/bin/activate' )
"endfunc
"
"
"func! s:clear_pane(pane)
"    call s:send_keys(a:pane, 'clear')
"    " wait for clear command to have completed before clearing
"    call system('(sleep 1;tmux clear-history -t ' . a:pane . ') &')
"endfunc
"
"
"func! s:select_debug()
"    call system('tmux select-pane -t ' . g:semicolon_debug_pane_id)
"endfunc
"
"
"func! s:select_ipython()
"    call system('tmux select-pane -t ' . g:semicolon_ipython_pane_id)
"endfunc


func! s:parse(...)
    if a:0 > 0
        if match(a:1, '.py') != -1
            return [expand(a:1), a:000[1:]]
        endif
    endif

    if &filetype != 'python'
        echo 'Filetype must be .py'
        return []
    endif

    return [expand('%:p'), a:000]
endfunc


func! s:exit()
    call semicolon#quit_debugger()
endfunc


func! s:load_pdbrc()
    let fname = s:project_dir . '/.pdbrc'
    if filereadable(fname)
        return readfile(fname)
    else
        return []
    endif
endfunc


func! s:save_pdbrc(pdbrc)
    let fname = s:project_dir . '/.pdbrc'
    if !empty(a:pdbrc)
        call writefile(a:pdbrc, fname)
    else
        call system('rm ' . fname)
    endif
endfunc


func! s:update_pdbrc_qf()
    let fname = s:project_dir . '/.pdbrc'
    if filereadable(fname)
        execute 'cgetfile ' . fname
    else
        call setqflist([])
    endif 
endfunc
