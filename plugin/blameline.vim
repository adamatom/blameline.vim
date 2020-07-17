if exists('g:blameline_loaded')
  finish
endif
let g:blameline_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

let g:blameline_enabled = get(g:, 'blameline_enabled', 0)

function! BlamelineToggle() abort
  if g:blameline_enabled == 0
    call blameline#Enable()
    call blameline#Refresh()
  else
    call blameline#Disable()
    call blameline#Hide()
  endif
endfunction

call blameline#Init()

:command! -nargs=0 BlamelineToggle call BlamelineToggle()

highlight default link Blameline Comment

let &cpo = s:save_cpo
unlet s:save_cpo
