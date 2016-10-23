set ignorecase
set smartcase
set relativenumber
set nocompatible

nmap <C-a> ggVG$

syntax on

" Vundle
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

call vundle#end()
filetype indent plugin on
