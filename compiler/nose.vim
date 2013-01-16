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
  command -nargs=* CompilerSet set <args>
endif


" make sure we set a virtual_env pre cmd if in one
if $VIRTUAL_ENV != ''
    let s:virtual_env_cmd = '.\ $VIRTUAL_ENV/bin/activate;\ '
else
    let s:virtual_env_cmd = ''
endif

let s:base_path = resolve(expand('<sfile>:h') . '/..')
let s:nose = s:base_path . '/python/nose_errfile.py'

CompilerSet efm=%f:%l:%m
CompilerSet shellpipe=--errfile=%s

let s:cmd = 'clear;\ ' . s:virtual_env_cmd . 'python\ ' . s:nose . '\ $*'

execute 'CompilerSet makeprg=' . s:cmd
