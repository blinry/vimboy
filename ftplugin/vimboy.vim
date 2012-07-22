" Vimboy - a dead simple personal wiki plugin
" Copyright (C) 2011  Sebastian Morr
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

if exists("s:loaded_vimboy")
    finish
endif
let s:loaded_vimboy = 1

let g:vimboy_autolink = 0
let g:vimboy_hl_deadlinks = 0

fu s:InitVimboy()

    let g:vimboy_dir = expand("%:p:h")."/"
    execute "cd ".g:vimboy_dir

    au BufWritePost * call <SID>UpdateLinks()
    au Syntax vimboy call <SID>UpdateLinks()

    do Syntax vimboy
    call s:DefineMappings()
endf

fu s:UpdateLinks()
    let currTab = tabpagenr()
    tabdo call s:UpdateLinksInThisTab()
    execute "tabn ".currTab
endf

fu s:UpdateLinksInThisTab()
    syntax clear
    syntax case match

    if g:vimboy_hl_deadlinks && ! g:vimboy_autolink
        syntax match Error /\[[^\]]*\]/
    endif

    let l:files = split(glob("*"),'[\r\n]\+')
    for l:file in l:files
        if g:vimboy_autolink
            execute 'syntax match Underlined /\v<('.l:file.')\ze.?>/'
        else
            execute 'syntax match Underlined /\['.l:file.'\]/'
        endif
    endfor
endf

fu s:DefineMappings()
    vnoremap <CR> :call <SID>OpenVisualSelection()<CR>
    nnoremap <CR> :call <SID>OpenLinkUnderCursor()<CR>
    noremap <2-LeftMouse> :call <SID>OpenLinkUnderCursor()<CR>

    nnoremap <Leader>wd :call DeletePage()<CR>
endf

fu s:OpenVisualSelection()
    let s:bak=@"
    normal! gvy
    call s:OpenPage(fnameescape(@"))
    let @"=s:bak
endf

fu s:OpenPage(name)
    execute "tabe ".a:name
endf

" Most. Ugly. Function. I. Have. Ever. Written.

fu s:OpenLinkUnderCursor()
    let s:bak=@"

    if g:vimboy_autolink
        if s:OnLink()
            normal! mc 

            normal! $
            let lineLength = col(".")
            normal! `c

            while col(".") > 1
                normal! h
                if !s:OnLink()
                    normal! l
                    break
                endif
            endwhile
            normal! ma`c

            while col(".") < lineLength
                normal! l
                if !s:OnLink()
                    normal! h
                    break
                endif
            endwhile
            normal! mb`av`by
        else
            normal! yiw
        endif
    else
        normal! yi[
    endif

    call s:OpenPage(fnameescape(@"))
    let @"=s:bak
endf

fu DeletePage()
    call delete(expand('%'))
    q!
    do Syntax vimboy
endf

fu s:OnLink()
    let stack = synstack(line("."), col("."))
    return !empty(stack)
endf

call s:InitVimboy()
