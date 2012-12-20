" vim-semicolon
" 
" https://github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.

" exit if not unix

if !has('unix')
    echoerr 'Not unix.'
    call s:exit()
endif


if !has('signs')
    echoerr "This version of vim does not support 'signs'."
    call s:exit()
endif


" move this somewhere else ?
if $TMUX == ''
    echoerr "Semicolon must be run within a tmux session.
        \ (Use 'tmux new vim' to start one.)"
    call s:exit()
endif

func! s:exit()
    echoerr 'Semicolon disabled.'
    finish
endfunc


nnoremap <silent> ;; :call semicolon#toggle_breakpoint()<cr>
nnoremap <silent> ;b :call semicolon#toggle_breakpoint_list()<cr>
nnoremap <silent> ;xx :call semicolon#delete_all_breakpoints()<cr>
nnoremap <silent> ;x :call semicolon#delete_file_breakpoints()<cr>
nnoremap <silent> ;q :call semicolon#quit_debugger()<cr>

nnoremap <silent> ;r :call semicolon#run()<cr>
nnoremap <silent> ;rr :call semicolon#run_args_prompt()<cr>
nnoremap <silent> ;R :call semicolon#run_prompt()<cr>


command! -nargs=? -complete=file SemicolonProject call semicolon#set_project(<f-args>)

call semicolon#init()



"nnoremap <silent> ;; :SemicolonToggleConsole<cr>
"nnoremap <silent> ;i :SemicolonIPython<cr>
"nnoremap <silent> ;ii :SemicolonRestartIPython<cr>
"           
"nnoremap ;T :SemicolonRunAllTests<cr>
"nnoremap ;R :call semicolon#run_prompt()<cr>


" Commands
"command! SemicolonToggleConsole call semicolon#toggle_console()
"command! SemicolonIPython call semicolon#select_ipython()
"command! SemicolonRestartIPython call semicolon#restart_ipython()
"
"command! -nargs=* -complete=file SemicolonRun call semicolon#run(<f-args>)
"command! -nargs=* -complete=file SemicolonDebugTest call semicolon#debug_test(<f-args>)
"command! SemicolonRunAllTests call semicolon#run_all_tests()

"autocmd VimLeave * call semicolon#quit()
