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

" syntastic
set statusline+=%#warningsmsg#
set statusline+={SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" rust
let g:rustfmt_autosave = 1

