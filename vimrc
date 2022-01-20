" VIM Config - Kevin Muncie
" http://vimhelp.appspot.com/
" http://learnvimscriptthehardway.stevelosh.com/
" Use `za` to toggle code folding at cursor location

" vim-plug plugin manager https://github.com/junegunn/vim-plug ---- {{{

call plug#begin()

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'nanotech/jellybeans.vim' " Theme
Plug 'kyoz/purify', { 'rtp': 'vim' }
Plug 'ap/vim-css-color',
" Plug 'rbong/vim-crystalline'
Plug 'vim-airline/vim-airline'
Plug 'vim-ctrlspace/vim-ctrlspace'
Plug 'edkolev/tmuxline.vim'
Plug 'tpope/vim-fugitive'
Plug 'cakebaker/scss-syntax.vim'
Plug 'posva/vim-vue'
Plug 'luochen1990/rainbow'
Plug 'mileszs/ack.vim'
call plug#end()

let $FZF_DEFAULT_COMMAND = 'ag -g ""'
" fzf.vim - ctrl+p for find git tracked files
nnoremap <silent> <C-p> :GFiles<CR>
" fzf.vim - ctrl+P for find in all files
nnoremap <silent> <C-P> :Files<CR>
" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
let g:fzf_colors = {
   \ 'fg':      ['fg', 'Normal'],
   \ 'bg':      ['bg', 'Normal'],
   \ 'hl':      ['fg', 'Comment'],
   \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
   \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
   \ 'hl+':     ['fg', 'Statement'],
   \ 'info':    ['fg', 'PreProc'],
   \ 'border':  ['fg', 'Ignore'],
   \ 'prompt':  ['fg', 'Conditional'],
   \ 'pointer': ['fg', 'Exception'],
   \ 'marker':  ['fg', 'Keyword'],
   \ 'spinner': ['fg', 'Label'],
   \ 'header':  ['fg', 'Comment'] }

let g:rainbow_active = 0 "0 if you want to enable it later via :RainbowToggle

" Settings for vim-ctrlspace plugin
set nocompatible
set hidden
set encoding=utf-8
set showtabline=0
let g:airline#extensions#tabline#enabled = 1 " Enable the list of buffers
let g:airline_exclude_preview = 1
let g:CtrlSpaceUseTabline = 1
if executable('ag')
   let g:CtrlSpaceGlobCommand = 'ag -l --nocolor -g ""'
endif

" }}}

" Core Display Configuration ---------------------- {{{
set title
set relativenumber
set ruler " Cursor position
set wrap " Wrap lines
set textwidth=0
set wrapmargin=0

set backspace=indent,eol,start

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

if executable('ag')
   let g:ackprg = 'ag --vimgrep'
endif

" Highlight nonascii characters
" https://stackoverflow.com/questions/16987362/how-to-get-vim-to-highlight-non-asc
syntax match nonascii "[^\x00-\x7F]"
highlight nonascii guibg=Red ctermbg=2

" }}}

" Core Theming ---------------------------------- {{{

" use 256 colors in Console mode if we think the terminal supports it
if &term =~? 'mlterm\|xterm'
   set background=dark
   set t_Co=256
endif

colorscheme purify
let g:airline_theme='purify'

autocmd FileType gitcommit set textwidth=90
" Colour the 91st column so that we don’t type over our limit
autocmd FileType gitcommit set colorcolumn=+1
" In Git commit messages, also colour the 72nd column (for titles)
autocmd FileType gitcommit set colorcolumn+=73


" }}}

" Crystalline Theme Settings ----------------- {{{
" function! StatusLine(current)
  " return (a:current ? crystalline#mode() . '%#Crystalline#' : '%#CrystallineInactive#')
        " \ . ' %f%h%w%m%r '
        " \ . (a:current ? '%#CrystallineFill# %{fugitive#head()} ' : '')
        " \ . '%=' . (a:current ? '%#Crystalline# %{&paste?"PASTE ":""}%{&spell?"SPELL ":""}' . crystalline#mode_color() : '')
        " \ . ' %{&ft}[%{&enc}][%{&ffs}] %l/%L %c%V %P '
" endfunction
"
" function! TabLine()
   " return crystalline#bufferline(0, 0, 1)
" endfunction
"
" let g:crystalline_statusline_fn = 'StatusLine'
" let g:crystalline_tabline_fn = 'TabLine'
" let g:crystalline_theme = 'purify'
"
" set showtabline=2
" set laststatus=2

" }}}

" Key Mappings ----------------------- {{{

" Latex snippets
nnoremap \scrip :-1read $HOME/.vim/scriptureCitation.tex<CR>2j$i

" Open vimrc in split for quick changes
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" Hit <leader> (should be \) + s to reload config after saving
nnoremap <leader>sv :source ~/.vimrc<CR>

" Hit ii to exit insert mode
inoremap ii <Esc>
nnoremap ii <Esc>
" Hit Ctrl+c to exit insert mode
inoremap <C-c> <Esc>

" Line movements
nnoremap H ^
nnoremap L $

" Yank till the end of the line
nnoremap Y y$

" Keep cursor centered when going through search results
nnoremap n nzzzv
nnoremap N Nzzzv
" Keep cursor in place when joining lines
nnoremap J mzJ'z

" Undo break points
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u
inoremap { {<c-g>u
inoremap ; ;<c-g>u

" Moving text
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
inoremap <C-j> <Esc>:m .+1<CR>==
inoremap <C-k> <Esc>:m .-2<CR>==
nnoremap <leader>k :m .-2<CR>==
nnoremap <leader>j :m .+1<CR>==

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

" Insert wrapping paragraph for Arabic stacked text, move cursor inside
function! StackedStart() abort
   let s:line=line(".")
   let html = "<p class=\"stackedTextContainer\" dir=\"rtl\" lang=\"ar\" xml:lang=\"ar\">\n\n</p>"
   let finalHtml = split(html, "\n")
   call append(s:line, finalHtml)
   normal! 2j
endfunction

" Thanks to Reddit u/duppy-ta for help with this
" https://www.reddit.com/r/vim/comments/bemdz2/custom_function_inserting_a_new_line_within_text/
function! ArabicSplitHTML() abort
   for lnum in range(a:lastline, a:firstline, -1)
      let words = split(getline(lnum))
      let htmlOne = "<span class=\"stackedText\">\n<span class=\"translatedText\" dir=\"ltr\" lang=\"en\" xml:lang=\"en\"></span>\n<span class=\"vernacularText\">"
      let htmlTwo = "</span>\n<span class=\"phoneticText\" dir=\"ltr\" lang=\"en\" xml:lang=\"en\"></span>\n</span>"
      let words_transformed = map(copy(words), 'htmlOne . v:val . htmlTwo')
      let all_lines = split(join(words_transformed, "\n"), "\n")
      execute lnum . "delete"
      call append(lnum-1, all_lines)
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

function! PhoSplitBlog() abort
   for lnum in range(a:lastline, a:firstline, -1)
      let words = split(getline(lnum))
      let words_transformed = map(copy(words), '"{{< word \"\" \"\" \"" . v:val . "\" >}}"')
      execute lnum . "delete"
      call append(lnum-1, words_transformed)
   endfor
endfunction
" Hit F5 to clear trailing whitespace at any time
nnoremap <silent> <F5> :let _s=@/ <Bar> call StripTrailingWhitespace() <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>

" quickfixopenall.vim
" Author:
"   Tim Dahlin
"
" Description:
"   Opens all the files in the quickfix list for editing.
"
" Usage:
"   1. Perform a vimgrep search
"       :vimgrep /def/ *.rb
"   2. Issue QuickFixOpenAll command
"       :QuickFixOpenAll

function!   QuickFixOpenAll()
   if empty(getqflist())
      return
   endif
   let s:prev_val = ""
   for d in getqflist()
      let s:curr_val = bufname(d.bufnr)
      if (s:curr_val != s:prev_val)
         exec "edit " . s:curr_val
      endif
      let s:prev_val = s:curr_val
   endfor
endfunction

command! QuickFixOpenAll call QuickFixOpenAll()

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

" Set .ts files to have proper markdown syntax highlighting
augroup typescript
   autocmd!
   autocmd BufNewFile,BufFilePre,BufRead *.ts set filetype=javascript
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

