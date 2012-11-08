" vim-semicolon
" 
" https://github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.

call semicolon#start()

nnoremap ;x :SemicolonClearBreakpoints<cr>
nnoremap ;b :SemicolonToggleBreakpointsList<cr>

command! SemicolonClearBreakpoints call semicolon#clear_breakpoints()
command! SemicolonToggleBreakpointsList call semicolon#toggle_breakpoints_list()

" used to track the quickfix window
augroup qfixtoggle
    autocmd!
    autocmd BufWinEnter quickfix call semicolon#set_qfix_win()
    autocmd BufWinLeave * call semicolon#unset_qfix_win()
augroup end

" exit if not unix
if !has('unix')
    finish
endif


" Key Commands
nnoremap <silent> ;; :SemicolonToggleConsole<cr>
nnoremap <silent> ;i :SemicolonIPython<cr>
nnoremap <silent> ;ii :SemicolonRestartIPython<cr>
           
nnoremap ;T :SemicolonRunAllTests<cr>
nnoremap ;R :call semicolon#run_prompt()<cr>

" Commands
command! SemicolonToggleConsole call semicolon#toggle_console()
command! SemicolonIPython call semicolon#select_ipython()
command! SemicolonRestartIPython call semicolon#restart_ipython()

command! -nargs=* -complete=file SemicolonRun call semicolon#run(<f-args>)
command! -nargs=* -complete=file SemicolonDebugTest call semicolon#debug_test(<f-args>)
command! SemicolonRunAllTests call semicolon#run_all_tests()

autocmd VimLeave * call semicolon#quit()
