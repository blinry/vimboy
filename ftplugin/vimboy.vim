" Vimboy - a dead simple personal wiki plugin
" Copyright (C) 2011-2013 Sebastian Morr <sebastian@morr.cc>
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

" Only process this script once
if exists("s:loaded_vimboy")
    finish
endif
let s:loaded_vimboy = 1

" By default, enable autolinks and disable deadlink highlighting
if !exists("g:vimboy_autolink")
    let g:vimboy_autolink = 1
endif
if !exists("g:vimboy_hl_deadlinks")
    let g:vimboy_hl_deadlinks = 0
endif

fu s:InitVimboy()
    let g:vimboy_dir = expand("%:p:h")."/"

    " Update known links upon writing and when 'syntax' option is set
    au BufWritePost * call <SID>UpdateLinks()
    au Syntax vimboy call <SID>UpdateLinks()

    do Syntax vimboy
    call s:DefineMappings()
endf

" Update links in all 'vimboy' tabs
fu s:UpdateLinks()
    let currTab = tabpagenr()
    tabdo call s:UpdateLinksInThisTab()
    execute "tabn ".currTab
endf

" Syntax highlight each filename of the current directory
fu s:UpdateLinksInThisTab()
    if &filetype != "vimboy"
        return
    endif

    syntax clear Underlined
    syntax case match

    if g:vimboy_hl_deadlinks && ! g:vimboy_autolink
        syntax match Error /\[[^\]]*\]/
    endif

    execute "cd ".g:vimboy_dir
    let l:files = split(glob("*"),'[\r\n]\+')
    execute "cd -"
    for l:file in l:files
        if l:file != expand('%')
            if g:vimboy_autolink
                execute 'syntax match Underlined /\c\V\<'.escape(l:file, '/\').'/'
            else
                execute 'syntax match Underlined /\c\['.l:file.'\]/'
            endif
        end
    endfor
endf

fu s:DefineMappings()
    vnoremap <CR> :call <SID>OpenVisualSelection()<CR>
    nnoremap <CR> :call <SID>OpenLinkUnderCursor()<CR>
    noremap <2-LeftMouse> :call <SID>OpenLinkUnderCursor()<CR>

    nnoremap <Leader>wd :call DeletePage()<CR>
endf

fu s:OpenVisualSelection()
    " Works by yanking the current visual selection, opening the unnamed
    " register, and restoring it afterwards
    let s:bak=@"
    normal! gvy
    call s:OpenPage(@")
    let @"=s:bak
endf

fu s:OpenPage(name)
    if !filereadable(g:vimboy_dir."/".a:name)
        execute "cd ".g:vimboy_dir
        let l:files = split(glob("*"),'[\r\n]\+')
        execute "cd -"
        for l:file in l:files
            if l:file =~ '\V\^'.escape(a:name, '/\').'\$'
                execute "tabe ".g:vimboy_dir."/".fnameescape(l:file)
                return
            endif
        endfor
    endif
    execute "tabe ".g:vimboy_dir."/".fnameescape(a:name)
endf

fu s:OpenLinkUnderCursor()
    let s:bak=@"
    normal! mc

    if g:vimboy_autolink
        if s:OnLink()
            " Get length of current line
            normal! $
            let lineLength = col(".")
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
            while col(".") < lineLength
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
    let @"=s:bak
endf

fu DeletePage()
    call delete(expand('%'))
    q!
    do Syntax vimboy
endf

" Is the cursor currently on a link?
fu s:OnLink()
    let stack = synstack(line("."), col("."))
    return !empty(stack)
endf

call s:InitVimboy()
