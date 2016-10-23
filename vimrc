set ignorecase
set smartcase
set relativenumber
set nocompatible
set backspace=indent,eol,start

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

call vundle#end()
filetype indent plugin on
