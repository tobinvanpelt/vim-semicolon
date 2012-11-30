" vim-semicolon
" 
" https://github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.

if !has('unix')
    finish
endif

if exists("current_compiler")
  finish
endif
let current_compiler = "nose"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet efm=%f:%l:\ fail:\ %m,%f:%l:\ error:\ %m
CompilerSet shellpipe=--err-file=%s

let s:nose_splitter = expand('<sfile>:h') . '/../python/nose_splitter.py'
let &l:makeprg='clear; python ' . s:nose_splitter .
            \ ' $* --with-results-splitter --with-doctest --doctest-tests'
