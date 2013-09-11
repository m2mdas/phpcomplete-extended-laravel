phpcomplete-extended-laravel
=============================

phpcomplete-extended-laravel is an extension of
[phpcomplete-extended](https://github.com/m2mdas/phpcomplete-extended) plugin
which provides autocomplete suggestions for
[laravel](https://github.com/laravel/laravel) projects. Following completion
types are supported right now,

* Facades
* Models

Also goto defenition and open doc functionality works as expected.

If [Unite.vim](https://github.com/Shougo/unite.vim) installed, following sources
are available,

* `laravel/facades` : Lists facades 
* `laravel/ioc`     : Lists ioc services
* `laravel/models`  : Lists models
* `laravel/routes`  : Lists routes

Demo video (click on the image to goto youtube)
-----------------------------------------------

[![ScreenShot](http://img.youtube.com/vi/UYMNjMH9TVE/maxresdefault.jpg)](http://www.youtube.com/watch?v=UYMNjMH9TVE)


Installation
------------
Same as [phpcomplete-extended](https://github.com/m2mdas/phpcomplete-extended),
just add following lines in `.vimrc`

## NeoBundle

    NeoBundle 'm2mdas/phpcomplete-extended-laravel'

## Vundle

    Bundle 'm2mdas/phpcomplete-extended-laravel'

For pathogen clone [the repository](https://github.com/m2mdas/phpcomplete-extended-laravel.git) to your
`.vim/bundle` directory.

## Future plan

* Package listing
* View file completion
* Ioc service completion

and many more.
