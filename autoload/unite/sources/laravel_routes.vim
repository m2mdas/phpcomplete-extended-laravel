"=============================================================================
" AUTHOR:  Mun Mun Das <m2mdas at gmail.com>
" FILE: laravel_routes.vim
" Last Modified: September 10, 2013
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

if !g:loaded_phpcomplete_extended_laravel
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:Cache = unite#util#get_vital().import('System.Cache')

let s:continuation = {}

function! unite#sources#laravel_routes#define() "{{{
    let sources = [ s:laravel_routes]
    return sources
endfunction"}}}

let s:laravel_routes = {
            \ 'name' : 'laravel/routes',
            \ 'description' : 'Lists Laravel routes',
            \ 'hooks' : {},
            \ }

function! s:laravel_routes.gather_candidates(args, context) "{{{
   if !phpcomplete_extended#laravel#is_valid_project()
       return []
   endif
   return s:get_route_entries(a:args, a:context)
endfunction"}}}

function! s:get_route_entries(args, context) "{{{
    let routes = phpcomplete_extended#laravel#get_routes()
    if empty(routes)
        return []
    endif
    let candidates = values(map(routes, "{
                \ 'word' : v:key,
                \ 'abbr' : v:key,
                \ 'kind' : 'jump_list',
                \ 'action__path' : v:val.position.file,
                \ 'action__line' : v:val.position.line
                \ }"
            \))
    return candidates
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker:expandtab:ts=4:sts=4:tw=78
