" VIM Config - Kevin Muncie

" -- Display
set title
set number
set ruler " Cursor position
set wrap " Wrap lines

set guioptions=T " Enable the toolbar
set showcmd

syntax on
colorscheme gruvbox " Custom color scheme in /vim folder
set background=dark " Applied to gruvbox color scheme set above
set colorcolumn=140

" -- Text editing preferences
set autoindent
set smartindent
set expandtab
set softtabstop=3
set shiftwidth=3
set showmatch
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" -- Key Mappings

" Hit <leader> (should be \) + s to reload config after saving
map <leader>s :source ~/.vimrc<CR>
" Hit ii to exit insert mode
map ii <Esc>
imap ii <Esc>

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

" Disable arrow keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

