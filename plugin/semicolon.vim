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
nnoremap <silent> ;b :call semicolon#toggle_breakpoint_list()<cr>
nnoremap <silent> ;xx :call semicolon#delete_all_breakpoints()<cr>
nnoremap <silent> ;q :call semicolon#quit_debugger()<cr>

nnoremap <silent> ;R :call semicolon#run_prompt()<cr>
nnoremap <silent> ;D :call semicolon#debug_prompt()<cr>

command! -nargs=? -complete=file SemicolonProject call semicolon#set_project(<f-args>)

" python file specific debugger mappings
autocmd FileType python nnoremap <silent> ;; :call semicolon#toggle_breakpoint()<cr>
autocmd FileType python nnoremap <silent> ;x :call semicolon#delete_file_breakpoints()<cr>

autocmd FileType python nnoremap <silent> ;r :call semicolon#run()<cr>
autocmd FileType python nnoremap <silent> ;rr :call semicolon#run_args_prompt()<cr>

autocmd FileType python nnoremap <silent> ;d :call semicolon#debug()<cr>
autocmd FileType python nnoremap <silent> ;dd :call semicolon#debug_args_prompt()<cr>

call semicolon#init()
