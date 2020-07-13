if exists('g:blameline_autoloaded')
  finish
endif
let g:blameline_autoloaded = 1

let s:save_cpo = &cpo
set cpo&vim

let s:git_root = ''
let s:blameline_prefix = get(g:, 'blameline_prefix', '   ')
let s:blameline_template = get(g:, 'blameline_template', '<author>, <author-time> • <summary>')
let s:blameline_date_format = get(g:, 'blameline_date_format', '%m/%d/%y %H:%M')
let s:blameline_user_name = ''
let s:blameline_user_email = ''
let s:blameline_info_fields = filter(map(split(s:blameline_template, ' '), {key, val -> matchstr(val, '\m\C<\zs.\{-}\ze>')}), {idx, val -> val != ''})
let s:prop_type_name = 'blameline_popup_marker'
let s:debug = 0


function! s:Head(array) abort
  if len(a:array) == 0
    return ''
  endif

  return a:array[0]
endfunction


function! s:IsFileInPath(file_path, path) abort
  if a:file_path =~? a:path
    return 1
  else
    return 0
  endif
endfunction


function! blameline#DrawPopup(message, line, buffer) abort
  let l:col = strlen(getline(a:line))
  let l:col = l:col == 0 ? 1 : l:col
  let l:propid = a:line . l:col

  if empty(prop_type_get(s:prop_type_name, {}))
    call prop_type_add(s:prop_type_name, {})
  endif

  call prop_add(a:line, l:col, {
        \ 'type': s:prop_type_name,
        \ 'length': 0,
        \ 'id': l:propid,
        \})

  let l:popup_winid = popup_create(s:blameline_prefix . a:message, #{
        \ textprop: s:prop_type_name,
        \ textpropid: l:propid,
        \ line: -1,
        \ col: l:col == 1 ? 1 : 2,
        \ fixed: 1,
        \ wrap: 0,
        \ highlight: 'Blameline'
        \})
endfunction


function! blameline#GenerateShowCallback(buffer, line) abort

  function! s:ShowCallback(channel) closure
    let l:result = ''

    while ch_status(a:channel, {'part': 'out'}) == 'buffered'
      let l:result = l:result . "\n" . ch_read(a:channel)
    endwhile

    let l:lines = split(l:result, '\n')
    if !exists('s:job_id') || len(l:lines) == 0
      return
    endif

    if s:debug == 1
      echom l:lines
    endif

    let l:info = {}
    let l:info['commit-short'] = split(l:lines[0], ' ')[0][:7]
    let l:info['commit-long'] = split(l:lines[0], ' ')[0]
    let l:hash_is_empty = empty(matchstr(info['commit-long'],'\c[0-9a-f]\{40}'))

    if l:hash_is_empty
      if l:result =~? 'fatal' && l:result =~? 'not a git repository'
        let g:blameline_enabled = 0
      endif
      return
    endif

    for line in l:lines[1:]
      let l:words = split(line, ' ')
      let l:property = l:words[0]
      let l:value = join(l:words[1:], ' ')
      if  l:property =~? 'time'
        let l:value = strftime(s:blameline_date_format, l:value)
      endif
      let l:value = escape(l:value, '&')
      let l:value = escape(l:value, '~')

      if l:value ==? s:blameline_user_name
        let l:value = 'You'
      elseif l:value ==? s:blameline_user_email
        let l:value = 'You'
      endif

      let l:info[l:property] = l:value
    endfor

    if l:info.author =~? 'Not committed yet'
      let l:info.author = 'You'
      let l:info.committer = 'You'
      let l:info.summary = 'Uncommitted changes'
    endif

    let l:message = s:blameline_template
    for field in s:blameline_info_fields
      let l:message = substitute(l:message, '\m\C<' . field . '>', l:info[field], 'g')
    endfor

    call blameline#DrawPopup(l:message, a:line, a:buffer)
    unlet s:job_id
  endfunction

  return funcref('s:ShowCallback')
endfunction


function! blameline#Show() abort
  if g:blameline_enabled == 0
    return
  endif

  let l:is_buffer_special = &buftype != '' ? 1 : 0
  if is_buffer_special
    return
  endif

  let l:path = expand('%:p')
  if s:IsFileInPath(l:path, s:git_root) == 0
    return
  endif

  let l:path = shellescape(l:path)
  let l:buffer_number = bufnr('')
  let l:line = line('.')

  let l:command = "bash -c \"git blame -w -p --contents - " . l:path . " -L " . l:line . ",+1 \""

  if s:debug == 1
    echom l:command
  endif
  try
    let s:job_id = job_start(l:command, {
          \ 'close_cb': blameline#GenerateShowCallback(l:buffer_number, l:line),
          \ 'in_io': 'buffer',
          \ 'in_buf': l:buffer_number,
          \})
  catch /^Vim\%((\a\+)\)\=:E631:/
  endtry
endfunction


function! blameline#Hide() abort
  let l:current_buffer_number = bufnr('')
  if !empty(prop_type_get(s:prop_type_name, {}))
    call prop_remove({
          \ 'type': s:prop_type_name,
          \ 'bufnr': l:current_buffer_number,
          \ 'all': 1,
          \})
  endif
endfunction


function! blameline#Refresh() abort
  if g:blameline_enabled == 0
    return
  endif

  call blameline#Hide()
  if exists('s:job_id')
    call job_stop(s:job_id)
    unlet s:job_id
  endif

  call blameline#Show()
endfunction


function! blameline#Enable() abort
  if g:blameline_enabled == 1
    return
  endif

  let g:blameline_enabled = 1
  call blameline#Init()
endfunction


function! blameline#Disable() abort
  if g:blameline_enabled == 0
    return
  endif

  let g:blameline_enabled = 0
  autocmd! blameline
endfunction


function! blameline#Init() abort
  if g:blameline_enabled == 0
    return
  endif

  if !exists('*popup_create')
    echohl ErrorMsg
    echomsg '[blameline.nvim] Needs popup feature.'
    echohl None
    return
  endif

  let l:result = split(system('git rev-parse --show-toplevel 2>/dev/null'), '\n')
  let s:git_root = s:Head(l:result)

  if s:git_root == ''
    let g:blameline_enabled = 0
    return
  endif

  let s:blameline_user_name = s:Head(split(system('git config --get user.name'), '\n'))
  let s:blameline_user_email = s:Head(split(system('git config --get user.email'), '\n'))

  augroup blameline
    autocmd!
    autocmd BufWritePost,CursorMoved * :call blameline#Refresh()
"    autocmd CursorMovedI * :call blameline#Hide()
  augroup END
endfunction

function! blameline#Debug() abort
  let s:debug = s:debug == 1 ? 0 : 1
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
