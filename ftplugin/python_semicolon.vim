" vim-semicolon
" 
" https://github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.

nnoremap <silent> <buffer> ;r :SemicolonRun<cr>
nnoremap <buffer> ;rr :call semicolon#run_args_prompt()<cr>

nnoremap <buffer> ;d :SemicolonDebugTest<cr>
nnoremap <buffer> ;t :SemicolonRunTest<cr>
nnoremap <buffer> ;tt :call semicolon#run_test_prompt()<cr>

nnoremap <buffer> ;<space> :SemicolonToggleBreakpoint<cr>

command! SemicolonToggleBreakpoint call semicolon#toggle_breakpoint()
command! -nargs=* -complete=file SemicolonRunTest call semicolon#run_test(<f-args>)
