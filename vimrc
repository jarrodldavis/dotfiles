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

set title
" emulate default `title` behavior without unnecessary suffixes
" filename (relative to current directory) followed by modification flags
" modifiable, readonly, and modified flags are wrapped in square brackets when present
let &titlestring="%f%( [%{&ma? '':'-'}%{&ro? '=':''}%{&modified? '+':''}]%)"

" Vundle
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

Plugin 'leafgarland/typescript-vim'

Plugin 'dart-lang/dart-vim-plugin'

Plugin 'christoomey/vim-titlecase'

call vundle#end()
filetype indent plugin on
