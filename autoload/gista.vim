"*****************************************************************************
" Gista Interface
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"*****************************************************************************

let s:save_cpo = &cpo
set cpo&vim


function! s:GistaLogin(options) abort " {{{
  let username = ''
  if type(a:options.login) == 1 " String
    let username = a:options.login
  endif
  let settings = extend({
        \ 'use_default_username': 0,
        \}, a:options)
  return gista#gist#raw#login(username, settings)
endfunction " }}}
function! s:GistaLogout(options) abort " {{{
  let settings = extend({
        \ 'permanently': 0,
        \}, a:options)
  return gista#gist#raw#logout(settings)
endfunction " }}}
function! s:GistaList(options) abort " {{{
  let lookup = a:options.list
  if type(lookup) == 0 " Digit
    unlet lookup
    let lookup = ''
  endif
  let options = extend({
        \ 'nocache': 0,
        \ 'page': -1,
        \}, a:options)
  let options = gista#utils#vital#pick(options, [
        \ 'nocache', 'page',
        \])
  return gista#interface#list(lookup, options)
endfunction " }}}
function! s:GistaOpen(options) abort " {{{
  let gistid = a:options.gistid
  let filename = split(a:options.filename, ';')
  let settings = {}
  if a:options.__bang__
    let settings.nocache = 1
  endif
  return gista#interface#open(gistid, filename, settings)
endfunction " }}}
function! s:GistaPost(options) abort " {{{
  let gistid = get(a:options, 'gistid', '')
  let options = extend({
        \ 'anonymous': 0,
        \ 'description': '',
        \ 'public': !g:gista#post_private,
        \}, a:options)
  let options = gista#utils#vital#pick(options, [
        \ 'anonymous', 'description', 'public',
        \])
  if empty(gistid)
    if get(a:options, 'multiple')
      return gista#interface#post_buffers(options)
    else
      return gista#interface#post(
            \ a:options.__range__[0],
            \ a:options.__range__[1],
            \ options)
    endif
  else
    let gist = gista#gist#api#get(gistid)
    let gist = extend({'owner': {'login': 'anonymous'}}, gist)
    if gist.owner.login == 'anonymous' ||
          \ gist.owner.login != gista#gist#raw#get_authenticated_user()
      " the user does not have a permission to edit the gist
      return s:GistaPost(gista#utils#vital#omit(a:options, ['gistid']))
    endif

    if has_key(a:options, 'public')
      redraw
      echohl GistaWarning
      echo  'Visibility modification is not supported:'
      echohl None
      echo  'It seems you have specified visibility to existing gist.'
      echo  'Gist API does not provide a way to modify the visibility thus '
      echon 'vim-gista cannot change the visibility (public or private) in '
      echon 'its interface.'
      echo  'Thus if you have specified different visibility, it will be '
      echon 'ignored.'
      echohl GistaQuestion
      call input('Hit enter to continue')
      echohl None
    endif
    if !exists('b:gistinfo')
      " the current buffer is not connected yet thus connect it
      call gista#interface#connect_action(gistid, expand('%:t'))
    endif
    return gista#interface#save(
          \ a:options.__range__[0],
          \ a:options.__range__[1],
          \ options)
  endif
endfunction " }}}
function! s:GistaRename(options) abort " {{{
  let gistid = a:options.gistid
  let filename = a:options.filename
  if type(a:options.rename) == 1
    let options = extend({
          \ 'new_filename': a:options.rename,
          \}, a:options)
  else
    let options = a:options
  endif
  return gista#interface#rename_action(gistid, filename, options)
endfunction " }}}
function! s:GistaRemove(options) abort " {{{
  let gistid = a:options.gistid
  let filename = a:options.filename
  return gista#interface#remove_action(gistid, filename, a:options)
endfunction " }}}
function! s:GistaDelete(options) abort " {{{
  let gistid = a:options.gistid
  return gista#interface#delete_action(gistid, a:options)
endfunction " }}}
function! s:GistaStar(options) abort " {{{
  let gistid = a:options.gistid
  return gista#interface#star_action(gistid, a:options)
endfunction " }}}
function! s:GistaUnstar(options) abort " {{{
  let gistid = a:options.gistid
  return gista#interface#unstar_action(gistid, a:options)
endfunction " }}}
function! s:GistaIsStarred(options) abort " {{{
  let gistid = a:options.gistid
  return gista#interface#is_starred_action(gistid, a:options)
endfunction " }}}
function! s:GistaFork(options) abort " {{{
  let gistid = a:options.gistid
  return gista#interface#is_starred_action(gistid, a:options)
endfunction " }}}
function! s:GistaBrowse(options) abort " {{{
  let gistid = a:options.gistid
  let filename = get(a:options, 'filename', '')
  return gista#interface#browse_action(gistid, filename, a:options)
endfunction " }}}
function! s:GistaDisconnect(options) abort " {{{
  let gistid = a:options.gistid
  let filename = get(a:options, 'filename', '')
  return gista#interface#disconnect_action(gistid, split(filename, ";"))
endfunction " }}}
function! s:GistaYank(options) abort " {{{
  let gistid = a:options.gistid
  let filename = get(a:options, 'filename', '')
  if type(a:options.yank) == 0
    let yank_method = g:gista#default_yank_method
  else
    let yank_method = a:options.yank
  endif
  return gista#interface#yank_action(gistid, filename, {
        \ 'yank_method': yank_method,
        \})
endfunction " }}}
function! s:GistaYankGistID(options) abort " {{{
  let gistid = a:options.gistid
  let filename = get(a:options, 'filename', '')
  return gista#interface#yank_gistid_action(gistid, filename)
endfunction " }}}
function! s:GistaYankURL(options) abort " {{{
  let gistid = a:options.gistid
  let filename = get(a:options, 'filename', '')
  return gista#interface#yank_url_action(gistid, filename)
endfunction " }}}


function! gista#Gista(options) abort " {{{
  if empty(a:options)
    " validation failed.
    return
  endif
  if !empty(get(a:options, 'login'))
    return s:GistaLogin(a:options)
  elseif !empty(get(a:options, 'logout'))
    return s:GistaLogout(a:options)
  elseif !empty(get(a:options, 'list'))
    return s:GistaList(a:options)
  elseif get(a:options, 'open')
    return s:GistaOpen(a:options)
  elseif get(a:options, 'post')
    return s:GistaPost(a:options)
  elseif get(a:options, 'rename')
    return s:GistaRename(a:options)
  elseif get(a:options, 'remove')
    return s:GistaRemove(a:options)
  elseif get(a:options, 'delete')
    return s:GistaDelete(a:options)
  elseif get(a:options, 'star')
    return s:GistaStar(a:options)
  elseif get(a:options, 'unstar')
    return s:GistaUnstar(a:options)
  elseif get(a:options, 'is-starred')
    return s:GistaIsStarred(a:options)
  elseif get(a:options, 'fork')
    return s:GistaFork(a:options)
  elseif get(a:options, 'browse')
    return s:GistaBrowse(a:options)
  elseif get(a:options, 'disconnect')
    return s:GistaDisconnect(a:options)
  elseif !empty(get(a:options, 'yank'))
    return s:GistaYank(a:options)
  elseif get(a:options, 'yank-gistid')
    return s:GistaYankGistID(a:options)
  elseif get(a:options, 'yank-url')
    return s:GistaYankURL(a:options)
  endif
endfunction " }}}
function! gista#define_highlights() abort " {{{
  highlight default link GistaTitle       Title
  highlight default link GistaError       ErrorMsg
  highlight default link GistaWarning     WarningMsg
  highlight default link GistaInfo        Comment
  highlight default link GistaQuestion    Question

  highlight default link GistaGistID      Tag
  highlight default link GistaPrivate     ErrorMsg
  highlight default link GistaDate        Comment
  highlight default link GistaTime        Comment
  highlight default link GistaFiles       Comment
  highlight default link GistaComment     Comment
  highlight default link GistaStatement   Statement
endfunction " }}}
function! gista#define_syntax() abort " {{{
  execute 'syntax match GistaGistID  /\[.\{20}\]/'
  execute 'syntax match GistaFiles   /^-.*/'
  execute 'syntax match GistaComment /^".*/'
  execute printf('syntax match GistaPrivate /%s/',
        \ g:gista#private_mark)
  execute 'syntax match GistaDate /\d\{4}\/\d\{2}\/\d\{2}/'
  execute 'syntax match GistaTime /\d\{2}:\d\{2}:\d\{2}/'
endfunction " }}}


" Variables {{{
let s:default_openers = {
      \ 'edit': 'edit',
      \ 'split': 'rightbelow split',
      \ 'vsplit': 'rightbelow vsplit',
      \}
let s:settings = {
      \ 'github_user': -1,
      \ 'gist_api_url': -1,
      \ 'directory': printf('"%s"', fnamemodify(expand('~/.gista/'), ':p')),
      \ 'tokens_directory': -1,
      \ 'gist_entries_cache_directory': -1,
      \ 'list_opener': '"topleft 20 split +set\\ winfixheight"',
      \ 'gist_default_opener': '"edit"',
      \ 'gist_default_opener_in_action': '"edit"',
      \ 'gist_default_filename': '"gist-file"',
      \ 'close_list_after_open': 0,
      \ 'auto_connect_after_post': 1,
      \ 'update_on_write': 2,
      \ 'enable_default_keymaps': 1,
      \ 'post_private': 0,
      \ 'interactive_description': 1,
      \ 'interactive_visibility': 1,
      \ 'include_invisible_buffers_in_multiple': 0,
      \ 'unite_smart_open_threshold': 1,
      \ 'unite_smart_open_method': '"open"',
      \ 'gistid_yank_format': '"{gistid}"',
      \ 'gistid_yank_format_with_file': '"{gistid}/{filename}"',
      \ 'gistid_yank_format_in_post': '"GistID: {gistid}"',
      \ 'gistid_yank_format_in_save': '"GistID: {gistid}"',
      \ 'default_yank_method': '"gistid"',
      \ 'auto_yank_after_post': 1,
      \ 'auto_yank_after_save': 1,
      \ 'private_mark': '"<PRIVATE>"',
      \ 'disable_python_client': 1,
      \ 'suppress_acwrite_info_message': 0,
      \ 'suppress_not_owner_acwrite_info_message': 0,
      \ 'warn_in_partial_save': 1,
      \ 'hide_private_gistid': 1,
      \}
function! s:deprecated(name, replacement) " {{{
  if exists("g:gista#" . a:name)
    echohl WarningMsg
    echo printf("g:gista#%s is deprecated. Use g:gista#%s instead.",
          \ a:name, a:replacement)
    echohl None

    if !exists("g:gista#" . a:replacement)
      execute printf("let g:gista#%s = g:gista#%s",
            \ a:name, a:replacement)
    endif
  endif
endfunction " }}}
function! s:init() " {{{
  call s:deprecated(
        \ 'auto_yank_gistid_after_post',
        \ 'auto_yank_after_post')
  call s:deprecated(
        \ 'auto_yank_gistid_after_save',
        \ 'auto_yank_after_save')

  for [key, value] in items(s:settings)
    if !exists('g:gista#' . key)
      execute 'let g:gista#' . key . ' = ' . value
    endif
  endfor
  let g:gista#gist_openers = extend(s:default_openers,
        \ get(g:, 'gista#gist_openers', {}))
  let g:gista#gist_openers_in_action = extend(g:gista#gist_openers,
        \ get(g:, 'gista#gist_openers_in_action', {}))
  " define default values
  if type(g:gista#tokens_directory) == 0
    unlet g:gista#tokens_directory
    let g:gista#tokens_directory = g:gista#directory . 'tokens/'
  endif
  if type(g:gista#gist_entries_cache_directory) == 0
    unlet g:gista#gist_entries_cache_directory
    let g:gista#gist_entries_cache_directory = g:gista#directory . 'gists/'
  endif
  if type(g:gista#github_user) == 0
    unlet g:gista#github_user
    let g:gista#github_user = get(g:, 'github_user', '')
    if empty(g:gista#github_user)
      let g:gista#github_user =
            \ gista#utils#vital#system('git config --get github.user')
      let g:gista#github_user = substitute(g:gista#github_user, "\n", '', '')
      if empty(g:gista#github_user)
        let g:gista#github_user = $GITHUB_USER
      endif
    endif
  endif
  if type(g:gista#gist_api_url) == 0
    unlet g:gista#gist_api_url
    let g:gista#gist_api_url = get(g:, 'gist_api_url', '')
    if empty(g:gista#gist_api_url)
      let g:gista#gist_api_url =
            \ gista#utils#vital#system('git config --get github.apiurl')
      let g:gista#gist_api_url = substitute(g:gista#gist_api_url, "\n", '', '')
      if empty(g:gista#gist_api_url)
        let g:gista#gist_api_url = 'https://api.github.com/'
      endif
    endif
  endif
endfunction
call s:init()
" }}}
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
