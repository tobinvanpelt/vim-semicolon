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


func! s:complete_project(...)
    return s:complete(g:semicolon_project_dir, a:1)
endfunc


func! s:complete_tests(...)
    return s:complete(g:semicolon_tests_dir, a:1)
endfunc


func! s:complete(ref, args)
    let base = expand(a:ref, ':p')
    let dirs = split(globpath(base, a:args . '*/'), '\n')
    let pys = split(globpath(base, a:args . '*.py'), '\n')
    let names = pys + dirs

    let result = []
    for item in names 
        let new_item = fnamemodify(item,':s?' . base . '/??')
        call add(result, new_item) 
    endfor

    return result
endfunc


" -----------------------------------------------------------------------------
" global debugger mappings
nnoremap ;. :SemicolonSetProject 

nnoremap <silent> ;b :call semicolon#toggle_breakpoint_list()<cr>
nnoremap <silent> ;xx :call semicolon#delete_all_breakpoints()<cr>
nnoremap <silent> ;q :call semicolon#quit_debugger()<cr>

nnoremap <silent> ;t :call semicolon#nosetest_current()<cr>
nnoremap <silent> ;tt :call semicolon#nosetests('--failed')<cr>
                                                            
nnoremap ;R :SemicolonRun 
nnoremap ;D :SemicolonDebugTest 
nnoremap ;T :SemicolonNosetests 

command! -nargs=? -complete=file SemicolonProjectDir call semicolon#set_project_dir(<f-args>)
command! -nargs=? -complete=file SemicolonTestsDir call semicolon#set_tests_dir(<f-args>)

command! -nargs=* -complete=file SemicolonRun call semicolon#run(<f-args>)
command! -nargs=1 -complete=file SemicolonDebugTest call semicolon#debug(<f-args>)
command! -nargs=* -complete=customlist,s:complete_tests SemicolonNosetests call semicolon#nosetests(<f-args>)


" python file specific debugger mappings
autocmd FileType python nnoremap <silent> ;; :call semicolon#toggle_breakpoint()<cr>
autocmd FileType python nnoremap <silent> ;x :call semicolon#delete_file_breakpoints()<cr>

autocmd FileType python nnoremap <silent> ;r :call semicolon#run_current(1)<cr>
autocmd FileType python nnoremap <silent> ;rr :call semicolon#run_current(0)<cr>

autocmd FileType python nnoremap <silent> ;d :call semicolon#debug_location(1)<cr>
autocmd FileType python nnoremap <silent> ;dd :call semicolon#debug_location(0)<cr>

call semicolon#init()

