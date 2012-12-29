" vim-semicolon plugin file
" 
" https://github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.


if !has('unix')
    echom 'Not unix.'
    finish
endif


if !has('signs')
    echom "This version of vim does not support 'signs'."
    echom 'Semicolon disabled.'
    finish
endif


" move this somewhere else ?
if $TMUX == ''
    echom "Semicolon must be run from within a tmux session."
    echom "(use 'tmux new vim' to start one)"
    echom 'Semicolon disabled.'
    finish
endif



" global debugger mappings
nnoremap ;. :SemicolonSetProject 

nnoremap <silent> ;b :call semicolon#toggle_breakpoint_list()<cr>
nnoremap <silent> ;xx :call semicolon#delete_all_breakpoints()<cr>
nnoremap <silent> ;q :call semicolon#quit_debugger()<cr>

nnoremap ;R :SemicolonRun 
nnoremap ;D :SemicolonDebugTest 

command! -nargs=? -complete=file SemicolonSetProject call semicolon#set_project(<f-args>)
command! -nargs=1 -complete=file SemicolonDebugTest call semicolon#debug(<f-args>)
command! -nargs=* -complete=file SemicolonRun call semicolon#run(<f-args>)


" python file specific debugger mappings
autocmd FileType python nnoremap <silent> ;; :call semicolon#toggle_breakpoint()<cr>
autocmd FileType python nnoremap <silent> ;x :call semicolon#delete_file_breakpoints()<cr>

autocmd FileType python nnoremap <silent> ;r :call semicolon#run_current(1)<cr>
autocmd FileType python nnoremap <silent> ;rr :call semicolon#run_current(0)<cr>

autocmd FileType python nnoremap <silent> ;d :call semicolon#debug_location(1)<cr>
autocmd FileType python nnoremap <silent> ;dd :call semicolon#debug_location(0)<cr>

call semicolon#init()
