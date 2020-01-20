" => built-ins

" ==> general settings
scriptencoding='utf-8'
set backspace=indent,eol,start
set cursorline

" ==> splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright

" ==> netrw
let g:netrw_hide = 1
let g:netrw_liststyle = 3
let g:netrw_list_hide = netrw_gitignore#Hide()
let g:netrw_preview = 1
let g:netrw_winsize = 20
nmap <C-\> :Explore<CR>
nmap <leader>t :Hexplore<CR>

" ==> searching
set ignorecase
set smartcase
set incsearch

" ==> line numbers
set number
set relativenumber

" ==> indentation
set expandtab
set tabstop=4
set shiftwidth=4

" => extensions

" ==> Yggdroot/indentLine
let g:indentLine_leadingSpaceChar = '·'
let g:indentLine_leadingSpaceEnabled = 1

" ==> airblade/vim-gitgutter
set updatetime=100
set signcolumn=yes

" ==> chriskempson/base16-vim
if filereadable(expand('~/.vimrc_background'))
  let base16colorspace = 256
  source ~/.vimrc_background
endif

" ==> ctrlpvim/ctrlp.vim
let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_extensions = ['mixed', 'tag', 'buffertag']
let g:ctrlp_map = '<C-P>'
let g:ctrlp_types = ['mixed', 'tag', 'buffertag', 'fil', 'buf', 'mru']
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_working_path_mode = 'ra'

" ==> easymotion/vim-easymotion

" ==> editorconfig/editorconfig-vim

" ==> idanarye/vim-merginal

" ==> int3/vim-extradite

" ==> junegunn/vim-slash

" ==> justinmk/vim-sneak
let g:sneak#use_ic_scs = 1
map f <Plug>Sneak_s
map F <Plug>Sneak_F

" ==> lambdalisue/gina.vim
cnoreabbrev git Gina

" ==> mhinz/vim-startify
let g:startify_skiplist = ['COMMIT_EDITMSG', 'pack/.*', 'doc/.*']

" ==> svermeulen/vim-cutlass
xnoremap x d
nnoremap xx dd
nnoremap X D

" ==> svermeulen/vim-subversive
nmap s <plug>(SubversiveSubstitute)
nmap ss <plug>(SubversiveSubstitueLine)
nmap S <plug>(SubversiveSubstituteToEndOfLine)
xmap s <plug>(SubversiveSubstitute)
xmap p <plug>(SubversiveSubstitute)
xmap P <plug>(SubversiveSubstitute)

" ==> svermeulen/vim-yoink
let g:yoinkIncludeDeleteOperations = 1
nmap <C-N> <plug>(YoinkPostPasteSwapBack)
nmap <C-M> <plug>(YoinkPostPasteSwapForward)
nmap p <plug>(YoinkPaste_p)
nmap P <plug>(YoinkPaste_P)
nnoremap x d

" ==> tpope/vim-commentary

" ==> tpope/vim-dispatch

" ==> tpope/vim-dotenv

" ==> tpope/vim-eunuch

" ==> tpope/vim-fugitive

" ==> tpope/vim-obsession

" ==> tpope/vim-repeat

" ==> tpope/vim-rhubarb

" ==> tpope/vim-sensible

" ==> tpope/vim-surround

" ==> tpope/vim-unimpaired

" ==> tpope/vim-vinegar

" ==> vim-airline/vim-airline
set laststatus=1
set noshowmode
set shortmess+=F
let g:airline_base16_improved_contrast = 1
let g:airline_detect_iminsert = 1
let g:airline_detect_modified = 1
let g:airline_detect_paste = 1
let g:airline_detect_spell = 1
let g:airline_detect_spelllang = 1
let g:airline_inactive_alt_sep = 1
let g:airline_powerline_fonts = 1
let g:airline_skip_empty_sections = 1
let g:airline_theme = 'base16_vim'
let g:airline#extensions#branch#format = 2
let g:airline#extensions#hunks#non_zero_only = 0
let g:airline#extensions#tabline#enabled = 1

" => load packages
packloadall

" => post-packload

" ==> lambdalisue/gina.vim
call gina#custom#mapping#nmap('status', '<C-J>', '<C-W><C-J>', { 'noremap': 1 })
call gina#custom#mapping#nmap('status', '<C-K>', '<C-W><C-K>', { 'noremap': 1 })
