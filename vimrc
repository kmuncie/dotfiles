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

" Disable arrow keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

