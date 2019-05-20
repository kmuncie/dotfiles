" VIM Config - Kevin Muncie
" http://vimhelp.appspot.com/
" http://learnvimscriptthehardway.stevelosh.com/
" Use `za` to toggle code folding at cursor location

" Core Display Configuration ---------------------- {{{
set title
set number
set ruler " Cursor position
set wrap " Wrap lines
set textwidth=0
set wrapmargin=0

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

" Highlight nonascii characters
" https://stackoverflow.com/questions/16987362/how-to-get-vim-to-highlight-non-asc
syntax match nonascii "[^\x00-\x7F]"
highlight nonascii guibg=Red ctermbg=2

" }}}

" Core Theming ---------------------------------- {{{
colorscheme gruvbox " Custom color scheme in /vim folder
let g:gruvbox_contrast_dark = 'hard'
set background=dark " Applied to gruvbox color scheme set above

autocmd FileType gitcommit set textwidth=90
" Colour the 91st column so that we don’t type over our limit
autocmd FileType gitcommit set colorcolumn=+1
" In Git commit messages, also colour the 72nd column (for titles)
autocmd FileType gitcommit set colorcolumn+=73

" use 256 colors in Console mode if we think the terminal supports it
if &term =~? 'mlterm\|xterm'
   set background=dark " Applied to gruvbox color scheme set above
   set t_Co=256
endif

" }}}

" Crystalline Theme Settings ----------------- {{{
function! StatusLine(current)
  return (a:current ? crystalline#mode() . '%#Crystalline#' : '%#CrystallineInactive#')
        \ . ' %f%h%w%m%r '
        \ . (a:current ? '%#CrystallineFill# %{fugitive#head()} ' : '')
        \ . '%=' . (a:current ? '%#Crystalline# %{&paste?"PASTE ":""}%{&spell?"SPELL ":""}' . crystalline#mode_color() : '')
        \ . ' %{&ft}[%{&enc}][%{&ffs}] %l/%L %c%V %P '
endfunction

function! TabLine()
  let l:vimlabel = has("nvim") ?  " NVIM " : " VIM "
  return crystalline#bufferline(2, len(l:vimlabel), 1) . '%=%#CrystallineTab# ' . l:vimlabel
endfunction

let g:crystalline_statusline_fn = 'StatusLine'
let g:crystalline_tabline_fn = 'TabLine'
let g:crystalline_theme = 'gruvbox'

set showtabline=2
set laststatus=2

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
Plug 'morhetz/gruvbox'
Plug 'rbong/vim-crystalline'
Plug 'edkolev/tmuxline.vim'
Plug 'tpope/vim-fugitive'
Plug 'cakebaker/scss-syntax.vim'
Plug 'posva/vim-vue'
Plug 'luochen1990/rainbow'
Plug 'mileszs/ack.vim'
call plug#end()

let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_by_filename = 1
let g:ctrlp_use_caching = 1
" Skip files listed in .gitignore (faster load time)
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
let g:rainbow_active = 0 "0 if you want to enable it later via :RainbowToggle

" }}}
