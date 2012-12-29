" vim-semicolon python block locator
" 
" github.com/tobinvanpelt/vim-semicolon.git
"
" Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
" See :help license.

let s:keys = '\(class\|def\)'


" get the indent of the current line
func! s:get_indent()
    let indent  = matchend(getline('.'), '\s*\S') - 1

    " handle all whitesapce
    if indent < 0
        let below = search('\s*\S', 'nW')
        let indent  = matchend(getline(below), '\s*\S') - 1

        " bottom of file
        if indent < 0
            let indent = 0
        endif
    endif

    return indent
endfunc


" resolve the given line number in terms of indent, key, and variable name
func! s:resolve_line(linenum)
    let line = getline(a:linenum)

    let indent = matchend(line, '^\s*')
    let key = matchstr(line, s:keys, indent) 

    if key == ''
        return []
    endif

    let start = matchend(line, '^\s*' . s:keys . '\s\+')
    let name = matchstr(line, '[A-Za-z0-9_]\+', start)

    return [indent, key, name]
endfunc


" get the current block 
func! s:get_block()
    " check if current line is a block declaration
    let info = s:resolve_line(line('.'))
    if len(info) > 0
        call insert(info, line('.'))
        return info
    endif

    " check for module level
    let _indent = s:get_indent() - 1  
    if _indent < 0
        return []
    endif
    
    " search above for the block
    let linenum = search('^\s\{0,' . _indent .'\}' . s:keys, 'bnW')
    let info = s:resolve_line(linenum)
    if len(info) == 0
        return []
    endif

    call insert(info, linenum)
    return info
endfunc


" get the full location
func! pylocator#get_location()
    let cpos = getpos('.')
    let name = ''

    while 1
        let info = s:get_block()
        if len(info) == 0
            break
        else
            let name = info[3] . '.' . name 
            "
            " move next block up
            let next_linenum = info[0] - 1
            if next_linenum == 0
                break
            endif

            call cursor(next_linenum, 0)
        endif
    endwhile

    " restore cursor position
    call setpos('.', cpos)

    if len(name) == 0
        return name
    else
        return name[:-2] 
    endif
endfunc
