let s:UNCACHED_ID = -103832729
let s:EMPTY_CACHE_CELL=[{}, {}]

" called only on BufEnter
function! elixir#indentcache#init() " {{{
  if !exists("b:elixir_indent_cache")
    let b:elixir_indent_cache = []
  endif
endfunction " }}}

" called on each edit of text
"
" assumption is that editing lineN affects only indent levels of following
" lines, but not the previous ones
"
" cache starts from index 1 (this is how vim's line() works
function! elixir#indentcache#invalidate() " {{{
  let line = line(".")

  " strict > instead of >= because we have extra unused element (index 0)
  " in array.
  if (len(b:elixir_indent_cache) > line)
    let b:elixir_indent_cache = b:elixir_indent_cache[0:line-1]
  end
endfunction " }}}

" get_cache_element() retrieves element from cache or returns s:UNCACHED_ID if
" cache not set yet. It has side-effects (initializing cache) and it is
" expected that get_cache_element() is called before set_cache_element()
"
" for each line we keep several caches:
" - cache_no==0 is cached results of elixir#indent() function itself (implies
"   col == 0)
" - cache_no==1 is cached result of elixir#indent#is_string_or_comment()
"
" WARNING: requesting not existing cache will result in silent, not reported error
function! elixir#indentcache#get_cache_element(cache_no, line, col) " {{{
  " strict > instead of >= because we have extra unused element (index 0)
  " in array.
  if (len(b:elixir_indent_cache) > a:line)
    let cache_element = b:elixir_indent_cache[a:line]

    if type(cache_element) == 0
      " cache filled with 0, so this line was never accessed yet
      let b:elixir_indent_cache[a:line] = deepcopy(s:EMPTY_CACHE_CELL)
      return s:UNCACHED_ID
    else
      let cache_element = cache_element[a:cache_no]
      if has_key(cache_element, a:col)
        return cache_element[a:col]
      else
        return s:UNCACHED_ID
      endif
    endif
  else
    call s:ensure_cache_len(a:line)
    let b:elixir_indent_cache[a:line] = deepcopy(s:EMPTY_CACHE_CELL)
    return s:UNCACHED_ID
  endif
endfunction " }}}

function! elixir#indentcache#set_cache_element(cache_no, line, col, value) " {{{
  " we expect cache to be big enough already
  " which means get_cache_element() was called before
  "
  " we expect that s:get_cache_element also filled line element with
  " dictionary, so this call is safe to do without any checks
  let b:elixir_indent_cache[a:line][a:cache_no][a:col] = a:value
endfunction " }}}

function! elixir#indentcache#is_uncached(value) " {{{
  return a:value == s:UNCACHED_ID
endfunction " }}}

function! s:ensure_cache_len(max_line) " {{{
  let cache_len = len(b:elixir_indent_cache)
  let empty_elements = range(0, a:max_line - cache_len)
  call map(empty_elements, "0")
  call extend(b:elixir_indent_cache, empty_elements)
  if len(b:elixir_indent_cache) != a:max_line + 1
    echom "wrong allocation of cache"
    debug echo "error"
  endif
endfunction " }}}
