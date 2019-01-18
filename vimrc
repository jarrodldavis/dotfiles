set ignorecase
set smartcase
set number
set relativenumber
set nocompatible
set backspace=indent,eol,start

set expandtab
set tabstop=4
set shiftwidth=4

nmap <C-a> ggVG$

nmap <A-o> o<Esc>
nmap <A-O> O<Esc>
nmap ø o<Esc>
nmap Ø O<Esc>

syntax on

" Vundle
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

Plugin 'leafgarland/typescript-vim'

Plugin 'dart-lang/dart-vim-plugin'

call vundle#end()
filetype indent plugin on