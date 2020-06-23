" Vimboy - a dead simple personal wiki plugin
" Copyright (C) 2011-2019 Sebastian Morr <sebastian@morr.cc>
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.

" Only process this script once, but initialize the buffer every time.
if exists("g:loaded_vimboy")
    call s:InitBuffer()
    finish
endif
let g:loaded_vimboy = 1

" By default, enable autolinks, disable deadlinks, and disable tab mode.
if !exists("g:vimboy_autolink")
    let g:vimboy_autolink = 1
endif
if !exists("g:vimboy_hl_deadlinks")
    let g:vimboy_hl_deadlinks = 0
endif
if !exists("g:vimboy_tabmode")
    let g:vimboy_tabmode = 0
endif

" We run this once per buffer.
fu s:InitBuffer()
    " Set base dir to dir the current file is in.
    let b:vimboy_dir = expand("%:p:h")

    " When writing a file, refresh syntax in all buffers,
    " because the links might have changed.
    au BufEnter <buffer> call s:UpdateLinks()

    " Define mappings
    vnoremap <buffer> <silent> <CR> :call <SID>OpenVisualSelection()<CR>
    nnoremap <buffer> <silent> <CR> :call <SID>OpenLinkUnderCursor()<CR>
    noremap <buffer> <silent> <2-LeftMouse> :call <SID>OpenLinkUnderCursor()<CR>
    nnoremap <buffer> <silent> <Leader>wd :call DeletePage()<CR>
endf

fu s:UpdateLinks()
    do syntax
endf

fu s:OpenVisualSelection()
    " Works by yanking the current visual selection, opening the unnamed
    " register, and restoring it afterwards.
    let s:bak=@"
    normal! gvy
    call s:OpenPage(@")
    let @"=s:bak
endf

fu s:OpenPage(name)
    if g:vimboy_tabmode
        let l:editcmd = "tabe"
    else
        let l:editcmd = "e"
    endif
    if !filereadable(b:vimboy_dir."/".a:name)
        execute "cd ".b:vimboy_dir
        let l:files = split(glob("*"),'[\r\n]\+')
        execute "cd -"
        for l:file in l:files
            if l:file =~? '\V\^'.escape(a:name, '/\').'\$'
                execute l:editcmd." ".b:vimboy_dir."/".fnameescape(l:file)
                return
            endif
        endfor
    endif
    execute l:editcmd." ".b:vimboy_dir."/".fnameescape(a:name)
endf

fu s:OpenLinkUnderCursor()
    let l:bak=@"
    normal! mc

    if g:vimboy_autolink
        if s:OnLink()
            " Get length of current line.
            normal! $
            let l:lineLength = col(".")
            normal! `c

            " Go left until not on link anymore, set mark a,
            " restore cursor position
            while col(".") > 1
                normal! h
                if !s:OnLink()
                    normal! l
                    break
                endif
            endwhile
            normal! ma`c

            " Same thing going right, setting mark b, yank from a to b
            " afterwards
            while col(".") < l:lineLength
                normal! l
                if !s:OnLink()
                    normal! h
                    break
                endif
            endwhile
            normal! mb`av`by`c
        else
            normal! yiw`c
        endif
    else
        normal! yi[`c
    endif

    call s:OpenPage(@")
    let @"=l:bak
endf

fu DeletePage()
    call delete(expand('%'))
    bd!
endf

" Is the cursor currently on a link?
fu s:OnLink()
    let l:stack = synstack(line("."), col("."))
    return !empty(l:stack)
endf

call s:InitBuffer()
