"=============================================================================
" AUTHOR:  Mun Mun Das <m2mdas at gmail.com>
" FILE: laravel_facades.vim
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
let s:save_cpo = &cpo
set cpo&vim

if !exists('g:loaded_phpcomplete_extended_laravel') && !g:loaded_phpcomplete_extended_laravel
    finish
endif

let s:Cache = unite#util#get_vital().import('System.Cache')

let s:continuation = {}

function! unite#sources#laravel_facades#define() "{{{
    let sources = [ s:laravel_facades]
    return sources
endfunction"}}}

let s:laravel_facades = {
            \ 'name' : 'laravel/facades',
            \ 'description' : 'Lists laravel routes',
            \ 'hooks' : {},
            \ }

function! s:laravel_facades.gather_candidates(args, context) "{{{
    if !phpcomplete_extended#laravel#is_valid_project()
        return []
    endif
    return s:get_facades_entries(a:args, a:context)
endfunction"}}}

function! s:get_facades_entries(args, context) "{{{
    let facades = phpcomplete_extended#laravel#get_facades()
    if empty(facades)
        return []
    endif
    let facade_keys = sort(keys(facades))
    let candidates = map(facade_keys, "{
                \ 'word' : v:val,
                \ 'abbr' : v:val,
                \ 'kind' : 'jump_list',
                \ 'action__path' : has_key(facades[v:val], 'facade_service_file')? facades[v:val].facade_service_file : '',
                \ 'action_line' : 0
                \ }"
            \)
    return candidates

endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker:expandtab:ts=4:sts=4:tw=78
