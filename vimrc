" VIM Config - Kevin Muncie

" -- Display
set title
set number
set ruler " Cursor position
set wrap " Wrap lines

set t_Co=256
set guioptions=T " Enable the toolbar
set showcmd
set ttimeoutlen=50

syntax on
colorscheme gruvbox " Custom color scheme in /vim folder
set background=dark " Applied to gruvbox color scheme set above
set colorcolumn=140
highlight ColorColumn ctermbg=1

" -- Text editing preferences
set autoindent
set smartindent
set expandtab
set softtabstop=3
set shiftwidth=3
set showmatch
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" -- Search preferences
set incsearch
set hlsearch

" Airline Theme
set laststatus=2
let g:airline_theme='wombat'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

"if !exists('g:airline_symbols')
   "let g:airline_symbols = {}
"endif

" unicode symbols
"let g:airline_left_sep = '»'
"let g:airline_left_sep = '▶'
"let g:airline_right_sep = '«'
"let g:airline_right_sep = '◀'
"let g:airline_symbols.linenr = '␊'
"let g:airline_symbols.linenr = '␤'
"let g:airline_symbols.linenr = '¶'
"let g:airline_symbols.branch = '⎇'
"let g:airline_symbols.paste = 'ρ'
"let g:airline_symbols.paste = 'Þ'
"let g:airline_symbols.paste = '∥'
"let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
"let g:airline_left_sep = ''
"let g:airline_left_alt_sep = ''
"let g:airline_right_sep = ''
"let g:airline_right_alt_sep = ''
"let g:airline_symbols.branch = ''
"let g:airline_symbols.readonly = ''
"let g:airline_symbols.linenr = ''

" -- Key Mappings
"
" Hit <leader> (should be \) + s to reload config after saving
map <leader>s :source ~/.vimrc<CR>
" Hit ii to exit insert mode
map ii <Esc>
imap ii <Esc>

" Paste Toggle
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

" Toggle between absolute and relative line numbering
" Enables relative numbers.
function! EnableRelativeNumbers()
  set number
  set relativenumber
endfunc

" Disables relative numbers.
function! DisableRelativeNumbers()
  set number
  set norelativenumber
endfunc

" NumberToggle toggles between relative and absolute line numbers
function! NumberToggle()
  if(&relativenumber == 1)
    call DisableRelativeNumbers()
    let g:relativemode = 0
  else
    call EnableRelativeNumbers()
    let g:relativemode = 1
  endif
endfunc

nnoremap <C-n> :call NumberToggle()<cr>

" Removes trailing spaces
function! StripTrailingWhitespace()
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
" Set nowrap on HTML files
autocmd BufNewFile,BufRead *.html setlocal nowrap
" Remove trailing write space on save
autocmd BufWritePre * call StripTrailingWhitespace()
" Set .md files to have proper markdown syntax highlighting
autocmd BufNewFile,BufFilePre,BufRead *.md set filetype=markdown

" Disable arrow keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>


" vim-plug plugin manager https://github.com/junegunn/vim-plug

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
call plug#end()

let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_by_filename = 1
let g:ctrlp_use_caching = 1
" Skip files listed in .gitignore (faster load time)
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

