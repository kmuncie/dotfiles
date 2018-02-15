" VIM Config - Kevin Muncie
" http://vimhelp.appspot.com/

" -- Display
set title
set number
set ruler " Cursor position
set wrap " Wrap lines

set guioptions=T " Enable the toolbar
set showcmd
set ttimeoutlen=50

colorscheme gruvbox " Custom color scheme in /vim folder
let g:gruvbox_contrast_dark = 'hard'
set background=dark " Applied to gruvbox color scheme set above
set colorcolumn=140
highlight ColorColumn ctermbg=1

" use 256 colors in Console mode if we think the terminal supports it
if &term =~? 'mlterm\|xterm'
   set background=dark " Applied to gruvbox color scheme set above
   set t_Co=256
endif

" -- Text editing preferences
set autoindent

" https://www.reddit.com/r/vim/wiki/tabstop
set tabstop=8
set softtabstop=3
set shiftwidth=3
set expandtab

set showmatch
set omnifunc=syntaxcomplete#Complete

" -- Search preferences
set incsearch
set hlsearch

" Airline Theme
set laststatus=2
let g:airline_theme='wombat'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1


" ------------------------
" -- Key Mappings
" ------------------------

" Hit <leader> (should be \) + s to reload config after saving
noremap <leader>s :source ~/.vimrc<CR>

" Hit ii to exit insert mode
noremap ii <Esc>
inoremap ii <Esc>

" Paste Toggle
noremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

" Toggle between absolute and relative line numbering
" Enables relative numbers.
function! EnableRelativeNumbers() abort
  set number
  set relativenumber
endfunction

" Disables relative numbers.
function! DisableRelativeNumbers() abort
  set number
  set norelativenumber
endfunction

" NumberToggle toggles between relative and absolute line numbers
function! NumberToggle() abort
  if(&relativenumber == 1)
    call DisableRelativeNumbers()
    let g:relativemode = 0
  else
    call EnableRelativeNumbers()
    let g:relativemode = 1
  endif
endfunction

nnoremap <C-n> :call NumberToggle()<cr>

" Removes trailing spaces
function! StripTrailingWhitespace() abort
   normal mZ
   let l:chars = col("$")
   %s/\s\+$//e
   if (line("'Z") != line(".")) || (l:chars != col("$"))
      echo "Trailing whitespace stripped\n"
   endif
   normal `Z
endfunction

" Hit F5 to clear trailing whitespace at any time
nnoremap <silent> <F5> :let _s=@/ <Bar> call StripTrailingWhitespace() <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>
" Comment a line at any time
autocmd FileType scss,javascript nnoremap <buffer> <localleader>c I//<esc>
" Remove trailing write space on save
autocmd BufWritePre * call StripTrailingWhitespace()
" Set .md files to have proper markdown syntax highlighting
autocmd BufNewFile,BufFilePre,BufRead *.md set filetype=markdown
" Set Silverstripe template files (.ss) to use xhtml syntax highlighting
autocmd BufNewFile,BufRead *.ss set filetype=xhtml

" Disable arrow keys in Normal, Visual, and Operator-pending modes
noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>
" Disable arrow keys in Insert mode
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Switch to English - mapping
nmap <Leader>e :<C-U>call EngType()<CR>
" Switch to Arabic - mapping
nmap <Leader>a :<C-U>call AraType()<CR>

" Switch to English - function
function! EngType()
" To switch back from Arabic
  set keymap= " Restore default (US) keyboard layout
  set norightleft
endfunction

" Switch to Arabic - function
function! AraType()
    set keymap=arabic-pc "Modified keymap. File in ~/.vim/keymap/
    set rightleft
endfunction

" ------------------------------------------------------------
" vim-plug plugin manager https://github.com/junegunn/vim-plug
" ------------------------------------------------------------

call plug#begin()

" Fuzzy file finder
Plug 'ctrlpvim/ctrlp.vim'
" File Tree Viewer
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
" vim-ailine
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'
Plug 'tpope/vim-fugitive'
Plug 'cakebaker/scss-syntax.vim'
Plug 'posva/vim-vue'
Plug 'luochen1990/rainbow'
call plug#end()

let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_by_filename = 1
let g:ctrlp_use_caching = 1
" Skip files listed in .gitignore (faster load time)
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
let g:rainbow_active = 1 "0 if you want to enable it later via :RainbowToggle

