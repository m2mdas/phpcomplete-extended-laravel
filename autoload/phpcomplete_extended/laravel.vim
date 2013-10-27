"=============================================================================
" AUTHOR:  Mun Mun Das <m2mdas at gmail.com>
" FILE: laravel.vim
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

if !exists('g:loaded_phpcomplete_extended') && !g:loaded_phpcomplete_extended
    finish
endif

let g:loaded_phpcomplete_extended_laravel = 1

let s:laravel_plugin = {
    \    'name': 'laravel'
    \}

if !exists("s:laravel_index")
    let s:laravel_index = {}
endif

function! s:laravel_plugin.init() "{{{
    let g:phpcomplete_extended_auto_add_use = 0
endfunction "}}}

function! s:laravel_plugin.is_valid_for_project() "{{{
endfunction "}}}

function! s:laravel_plugin.set_index(index) "{{{
    call s:set_index(a:index)
endfunction "}}}

function! s:set_index(index) "{{{
    let s:laravel_index = a:index
endfunction "}}}

function! s:laravel_plugin.resolve_fqcn(fqcn) "{{{
    return s:resolve_fqcn(a:fqcn)
endfunction "}}}

function! s:laravel_plugin.get_fqcn(parentFQCN, token_data) "{{{
    return s:get_fqcn(a:parentFQCN, a:token_data)
endfunction "}}}

function! s:laravel_plugin.get_inside_quote_menu_entries(parentFQCN, token_data) "{{{
    return []
endfunction "}}}

function! s:resolve_fqcn(fqcn) "{{{
    let fqcn = a:fqcn
    if has_key(s:laravel_index['facades'], fqcn)
        return s:laravel_index['facades'][fqcn]['facade_service_fqcn']

    elseif has_key(s:laravel_index['models'], fqcn)
        return s:laravel_index['models'][fqcn].fqcn
    elseif match(fqcn, 'ioc:') == 0
        let ioc_service = matchstr(fqcn, 'ioc:\zs.*')
        if has_key(s:laravel_index['ioc_list'], ioc_service)
            return s:laravel_index['ioc_list'][ioc_service]
        endif
    endif

    return fqcn
endfunction "}}}

function! s:get_fqcn(parentFQCN, token_data) "{{{
    let token_data = a:token_data
    let parentFQCN = a:parentFQCN
    let methodPropertyText = token_data.methodPropertyText
    let insideBraceText = token_data.insideBraceText
    let fqcn = ""
    let parentFQCNData = phpcomplete_extended#getClassData(parentFQCN)

    if has_key(a:token_data, 'start') && a:token_data.start == 1 
        \ && has_key(s:laravel_index['models'], methodPropertyText)

        " models
        return s:laravel_index['models'][methodPropertyText].fqcn

    elseif has_key(a:token_data, 'start') && a:token_data.start == 1 
        \ && has_key(s:laravel_index['facades'], methodPropertyText) 

        "resolve facade
        let facade_service = s:laravel_index['facades'][methodPropertyText]['facade_service']
        return 'ioc:'. facade_service


    elseif !empty(parentFQCN) && match(parentFQCN, 'ioc:') == 0 

        "resolve facade
        let ioc_service = matchstr(parentFQCN, 'ioc:\zs.*')
        if has_key(s:laravel_index['ioc_list'], ioc_service)
            let service_fqcn = s:laravel_index['ioc_list'][ioc_service]
            let isMethod = has_key(token_data,"isMethod")? token_data.isMethod : 0
            let type = isMethod? "method" : "property"
            let [fqcn, isArray] = phpcomplete_extended#getFQCNForClassProperty(type, methodPropertyText, service_fqcn, 0)
            return fqcn
        endif
    endif

    return ""
endfunction "}}}

function! s:laravel_plugin.get_menu_entries(fqcn, base, is_this, is_static) "{{{
    return s:get_menu_entries(a:fqcn, a:base, a:is_this, a:is_static)
endfunction "}}}

function! s:get_menu_entries(fqcn, base, is_this, is_static) "{{{
    if a:fqcn == "" && b:completeContext.complete_type == 'nonclass'
        "start 
        let menu_entries = []
        let laravel_index = deepcopy(s:laravel_index)
        let facade_entries = values(map(laravel_index['facades'], "{
                    \ 'word': v:key,
                    \ 'menu': printf('%s (Facade)', v:val.facade_service_fqcn)
                    \ }"
                \))
        let model_menu_entries  = values(map(laravel_index['models'], "{
                    \ 'word': v:key,
                    \ 'menu': printf('%s (Model)', v:val.fqcn)
                    \ }"
                \))
        let menu_entries += facade_entries
        let menu_entries += model_menu_entries
        return filter(menu_entries, 'v:val.word =~ "^' . a:base .'"')

    elseif match(a:fqcn, 'ioc:') == 0  "complete facade
        let menu_entries =[]
        let is_static = 0
        let is_this = 0
        let ioc_service = matchstr(a:fqcn, 'ioc:\zs.*')
        if has_key(s:laravel_index['ioc_list'], ioc_service)
            let service_fqcn = s:laravel_index['ioc_list'][ioc_service]
            let service_menu_entries = phpcomplete_extended#getMenuEntries(service_fqcn, a:base, is_this, is_static)
            let menu_entries = extend(service_menu_entries, menu_entries)
        endif

        if has_key(s:laravel_index['manager_fqcns'], service_fqcn) 
            \ && s:laravel_index['manager_fqcns'][service_fqcn] != ""

            let manager_fqcn = s:laravel_index['manager_fqcns'][service_fqcn]
            let manager_fqcn_menu_entries =  phpcomplete_extended#getMenuEntries(manager_fqcn, a:base, is_this, is_static)
            let menu_entries = extend(manager_fqcn_menu_entries, menu_entries)
        endif
        return menu_entries
    endif

    return []
endfunction "}}}

function! phpcomplete_extended#laravel#define() "{{{
    let is_laravel_project = filereadable(phpcomplete_extended#util#substitute_path_separator(
                \ getcwd().'/bootstrap/start.php'))

    if is_laravel_project
        return s:laravel_plugin
    endif
    return {}
endfunction "}}}

function! phpcomplete_extended#laravel#is_valid_project() "{{{
    let is_valid = phpcomplete_extended#is_phpcomplete_extended_project() && !empty(s:laravel_index)
    if !is_valid
        echohl WarningMsg | echo  "Not a Valid Laravel project" | echohl None
    endif
    return is_valid
endfunction "}}}

function! phpcomplete_extended#laravel#get_facades() "{{{
    return deepcopy(s:laravel_index['facades'])
endfunction "}}}

function! phpcomplete_extended#laravel#get_ioc_lists() "{{{
    return deepcopy(s:laravel_index['ioc_list'])
endfunction "}}}

function! phpcomplete_extended#laravel#get_ioc_file() "{{{
    return deepcopy(s:laravel_index['ioc_file'])
endfunction "}}}

function! phpcomplete_extended#laravel#get_routes() "{{{
    return deepcopy(s:laravel_index['routes'])
endfunction "}}}

function! phpcomplete_extended#laravel#get_models() "{{{
    return deepcopy(s:laravel_index['models'])
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker:expandtab:ts=4:sts=4:tw=78
