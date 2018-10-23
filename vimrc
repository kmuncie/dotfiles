" VIM Config - Kevin Muncie
" http://vimhelp.appspot.com/
" http://learnvimscriptthehardway.stevelosh.com/
" Use `za` to toggle code folding at cursor location

" Core Display Configuration ---------------------- {{{
set title
set number
set ruler " Cursor position
set wrap " Wrap lines

set guioptions=T " Enable the toolbar
set showcmd
set ttimeoutlen=50

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

" Mac Clipboard Support
set clipboard=unnamed

" }}}

" Core Theming ---------------------------------- {{{
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

" }}}

" Airline Theme Settings ----------------- {{{
set laststatus=2
let g:airline_theme='wombat'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_powerline_fonts = 1

" }}}

" Key Mappings ----------------------- {{{

" Open vimrc in split for quick changes
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" Hit <leader> (should be \) + s to reload config after saving
nnoremap <leader>sv :source ~/.vimrc<CR>

" Hit ii to exit insert mode
nnoremap ii <Esc>
inoremap ii <Esc>

" Line movements
nnoremap H ^
nnoremap L $

" Operator-pending mappings
" <operator> inside next/last <bracket-type>
onoremap in( :<c-u>normal! f(vi(<cr>
onoremap il( :<c-u>normal! F(vi(<cr>
onoremap in{ :<c-u>normal! f{vi{<cr>
onoremap il{ :<c-u>normal! F{vi{<cr>
onoremap in[ :<c-u>normal! f[vi[<cr>
onoremap il[ :<c-u>normal! F[vi[<cr>

" Paste Toggle
noremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>

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

" }}}

" Functions (Line Numbering, Strip Whitespace) ----------------- {{{
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

" Transform words into Arabic Blog syntax
function! ArabicSplitBlog() abort
   for lnum in range(a:lastline, a:firstline, -1)
      let words = split(getline(lnum))
      let words_transformed = map(copy(words), '"{{< word \"\" \"" . v:val . "\" \"\" >}}"')
      execute lnum . "delete"
      call append(lnum-1, words_transformed)
   endfor
endfunction

function! EnglishSplitBlog() abort
   for lnum in range(a:lastline, a:firstline, -1)
      let words = split(getline(lnum))
      let words_transformed = map(copy(words), '"{{< word \"" . v:val . "\" \"\" \"\" >}}"')
      execute lnum . "delete"
      call append(lnum-1, words_transformed)
   endfor
endfunction

" Hit F5 to clear trailing whitespace at any time
nnoremap <silent> <F5> :let _s=@/ <Bar> call StripTrailingWhitespace() <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>

" }}}

" Autocommands ------------------ {{{

" vimrc code folding when three curly braces are on a line
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END

" Comment a line at any time
augroup comment_line
   autocmd!
   autocmd FileType scss,javascript nnoremap <buffer> <localleader>c I//<esc>
augroup END

" Remove trailing write space on save
augroup white_space
   autocmd!
   autocmd BufWritePre * call StripTrailingWhitespace()
augroup END

" Set .md files to have proper markdown syntax highlighting
augroup markdown
   autocmd!
   autocmd BufNewFile,BufFilePre,BufRead *.md set filetype=markdown
augroup END

" Set Silverstripe template files (.ss) to use xhtml syntax highlighting
augroup silverstripe
   autocmd!
   autocmd BufNewFile,BufRead *.ss set filetype=xhtml
augroup END

" }}}

" Arabic/English Quick Switching ------------------- {{{

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

" }}}

command! -nargs=* -complete=shellcmd R new | setlocal buftype=nofile bufhidden=hide noswapfile | r !<args>

" vim-plug plugin manager https://github.com/junegunn/vim-plug ---- {{{

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

" }}}
