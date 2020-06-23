highlight link vimboyLink Underlined
highlight link vimboyDeadlink Error

syntax clear vimboyLink
syntax clear vimboyDeadlink

if exists("b:vimboy_dir")
    if g:vimboy_hl_deadlinks && ! g:vimboy_autolink
        syntax match vimboyDeadlink /\[[^\]]*\]/
    endif

    " Syntax highlight each filename in the vimboy directory.
    execute "cd ".b:vimboy_dir
    let s:files = split(glob("*"),'[\r\n]\+')
    execute "cd -"
    for s:file in s:files
        if s:file != expand('%')
            if g:vimboy_autolink
                execute 'syntax match vimboyLink /\c\V\<'.escape(s:file, '/\').'/'
            else
                execute 'syntax match vimboyLink /\c\['.s:file.'\]/'
            endif
        end
    endfor
endif
