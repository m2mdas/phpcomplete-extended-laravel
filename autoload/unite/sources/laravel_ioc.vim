"=============================================================================
" AUTHOR:  Mun Mun Das <m2mdas at gmail.com>
" FILE: laravel_ioc.vim
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

if !g:loaded_phpcomplete_extended_laravel
    finish
endif

let s:Cache = unite#util#get_vital().import('System.Cache')

let s:continuation = {}

function! unite#sources#laravel_ioc#define() "{{{
    let sources = [ s:laravel_ioc]
    return sources
endfunction"}}}

let s:laravel_ioc = {
            \ 'name' : 'laravel/ioc',
            \ 'description' : 'List laravel ioc',
            \ 'hooks' : {},
            \ }

function! s:laravel_ioc.gather_candidates(args, context) "{{{
   if !phpcomplete_extended#laravel#is_valid_project()
       return []
   endif
   return s:get_ioc_entries(a:args, a:context)
endfunction"}}}

function! s:get_ioc_entries(args, context) "{{{
    let ioc_file = phpcomplete_extended#laravel#get_ioc_file()
    let ioc_lists = phpcomplete_extended#laravel#get_ioc_lists()
    if empty(ioc_file)
        return []
    endif
    let ioc_file_keys = sort(keys(ioc_file))
    let candidates = map(ioc_file_keys, "{
                \ 'word' : v:val,
                \ 'abbr' : v:val,
                \ 'kind' : 'jump_list',
                \ 'action__path' : ioc_file[v:val],
                \ 'action__line' : 0
                \ }"
            \)
    return candidates
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker:expandtab:ts=4:sts=4:tw=78
