"Use Vim settings, rather then Vi settings (much better!).
"This must be first, because it changes other options as a side effect.
set nocompatible " use vim defaults
set scrolloff=3	" keep 3 lines when scrolling

"Use pathogen to load all bundles
call pathogen#runtime_append_all_bundles()

"allow backspacing over everything in insert mode
set backspace=indent,eol,start

"store lots of :cmdline history
set history=1000
"lots of undo
set undolevels=1000

set showcmd	 "show incomplete cmds down the bottom
set showmode	"show current mode down the bottom

set incsearch	"find the next match as we type the search
set hlsearch	"hilight searches by default
set showmatch	" show matching parenthesis

set nowrap		"don't wrap lines
set linebreak	 "wrap lines at convenient points

" This isn't the 70s no more backup and swp files
set noswapfile
set nobackup

set number " show line numbers

"statusline setup
set statusline=%f		 "tail of the filename

"display a warning if fileformat isnt unix
set statusline+=%#warningmsg#
set statusline+=%{&ff!='unix'?'['.&ff.']':''}
set statusline+=%*

"display a warning if file encoding isnt utf-8
set statusline+=%#warningmsg#
set statusline+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}
set statusline+=%*

set statusline+=%h		"help file flag
set statusline+=%y		"filetype
set statusline+=%r		"read only flag
set statusline+=%m		"modified flag

"display a warning if &et is wrong, or we have mixed-indenting
set statusline+=%#error#
set statusline+=%{StatuslineTabWarning()}
set statusline+=%*

set statusline+=%{StatuslineTrailingSpaceWarning()}

set statusline+=%{StatuslineLongLineWarning()}

"display a warning if &paste is set
set statusline+=%#error#
set statusline+=%{&paste?'[paste]':''}
set statusline+=%*

set statusline+=%=		"left/right separator
set statusline+=%{StatuslineCurrentHighlight()}\ \ "current highlight
set statusline+=%c,	 "cursor column
set statusline+=%l/%L	 "cursor line/total lines
set statusline+=\ %P	"percent through file
set laststatus=2

" Search mappings: These will make it so that going to the next one in a
" search will center on the line it's found in.
map N Nzz
map n nzz

" Space will toggle folds!
nnoremap <space> za

" Next Tab
nnoremap <silent> <C-Right> :tabnext<CR>

" Previous Tab
nnoremap <silent> <C-Left> :tabprevious<CR>

" New Tab
nnoremap <silent> <C-t> :tabnew<CR>

" This is totally awesome - remap jj to escape in insert mode.	You'll never type jj anyway, so it's great!
inoremap jj <Esc>
inoremap kk <Esc>

" Make resizing split windows easier TODO: doesn't seem to work
nmap <C-Left> :vertical resize -2<CR>
nmap <C-Right> :vertical resize +2<CR>
nmap <C-Up> :resize +2<CR>
nmap <C-Down> :resize -2<CR>


"recalculate the trailing whitespace warning when idle, and after saving
autocmd cursorhold,bufwritepost * unlet! b:statusline_trailing_space_warning

"return '[\s]' if trailing white space is detected
"return '' otherwise
function! StatuslineTrailingSpaceWarning()
	if !exists("b:statusline_trailing_space_warning")

		if !&modifiable
			let b:statusline_trailing_space_warning = ''
			return b:statusline_trailing_space_warning
		endif

		if search('\s\+$', 'nw') != 0
			let b:statusline_trailing_space_warning = '[\s]'
		else
			let b:statusline_trailing_space_warning = ''
		endif
	endif
	return b:statusline_trailing_space_warning
endfunction


"return the syntax highlight group under the cursor ''
function! StatuslineCurrentHighlight()
	let name = synIDattr(synID(line('.'),col('.'),1),'name')
	if name == ''
		return ''
	else
		return '[' . name . ']'
	endif
endfunction

"recalculate the tab warning flag when idle and after writing
autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning

"return '[&et]' if &et is set wrong
"return '[mixed-indenting]' if spaces and tabs are used to indent
"return an empty string if everything is fine
function! StatuslineTabWarning()
	if !exists("b:statusline_tab_warning")
		let b:statusline_tab_warning = ''

		if !&modifiable
			return b:statusline_tab_warning
		endif

		let tabs = search('^\t', 'nw') != 0

		"find spaces that arent used as alignment in the first indent column
		let spaces = search('^ \{' . &ts . ',}[^\t]', 'nw') != 0

		if tabs && spaces
			let b:statusline_tab_warning =	'[mixed-indenting]'
		elseif (spaces && !&et) || (tabs && &et)
			let b:statusline_tab_warning = '[&et]'
		endif
	endif
	return b:statusline_tab_warning
endfunction

"recalculate the long line warning when idle and after saving
autocmd cursorhold,bufwritepost * unlet! b:statusline_long_line_warning

"return a warning for "long lines" where "long" is either &textwidth or 80 (if
"no &textwidth is set)
"
"return '' if no long lines
"return '[#x,my,$z] if long lines are found, were x is the number of long
"lines, y is the median length of the long lines and z is the length of the
"longest line
function! StatuslineLongLineWarning()
	if !exists("b:statusline_long_line_warning")

		if !&modifiable
			let b:statusline_long_line_warning = ''
			return b:statusline_long_line_warning
		endif

		let long_line_lens = s:LongLines()

		if len(long_line_lens) > 0
			let b:statusline_long_line_warning = "[" .
						\ '#' . len(long_line_lens) . "," .
						\ 'm' . s:Median(long_line_lens) . "," .
						\ '$' . max(long_line_lens) . "]"
		else
			let b:statusline_long_line_warning = ""
		endif
	endif
	return b:statusline_long_line_warning
endfunction

"return a list containing the lengths of the long lines in this buffer
function! s:LongLines()
	let threshold = (&tw ? &tw : 80)
	let spaces = repeat(" ", &ts)

	let long_line_lens = []

	let i = 1
	while i <= line("$")
		let len = strlen(substitute(getline(i), '\t', spaces, 'g'))
		if len > threshold
			call add(long_line_lens, len)
		endif
		let i += 1
	endwhile

	return long_line_lens
endfunction

"find the median of the given array of numbers
function! s:Median(nums)
	let nums = sort(a:nums)
	let l = len(nums)

	if l % 2 == 1
		let i = (l-1) / 2
		return nums[i]
	else
		return (nums[l/2] + nums[(l/2)-1]) / 2
	endif
endfunction

if v:version >= 703
	"undo settings
	set undodir=~/.vim/undofiles
	set undofile

	set colorcolumn=+1
endif

"indent settings
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set shiftround " use multiple of shiftwidth when indenting with '<' or '>'
set smarttab " insert tabs on start of line according to shiftwidth not tabstop
set autoindent " set auto-indenting on for programming
set copyindent " copy previous indentation on autoindenting


function! Spacing(tabs, size)
	execute "set shiftwidth=".a:size."\nset softtabstop=".a:size."\nset tabstop=".a:size
	if a:tabs
		set noexpandtab
	else
		set expandtab
	endif
endfunction

function! Tabs(size)
	call Spacing(1, a:size)
endfunction

function! Spaces(size)
	call Spacing(0, a:size)
endfunction

"Omnicompletion with ctrl-space
inoremap <expr> <C-Space> pumvisible() \|\| &omnifunc == '' ?
\ "\<lt>C-n>" :
\ "\<lt>C-x>\<lt>C-o><c-r>=pumvisible() ?" .
\ "\"\\<lt>c-n>\\<lt>c-p>\\<lt>c-n>\" :" .
\ "\" \\<lt>bs>\\<lt>C-n>\"\<CR>"
imap <C-@> <C-Space>

"folding settings
set foldmethod=indent	 "fold based on indent
set foldnestmax=3	"deepest fold is 3 levels
set nofoldenable	"dont fold by default

set wildmode=list:longest	 "make cmdline tab completion similar to bash
set wildmenu				"enable ctrl-n and ctrl-p to scroll thru matches
set wildignore=*.o,*.obj,*~,*.swp,*.bak,*.pyc,*.class "stuff to ignore when tab completing

set title "change the terminal's title

" stop frakkin beeping
set visualbell
set noerrorbells

"display tabs and trailing spaces
set list
"set listchars=tab:▷⋅,trail:⋅,nbsp:⋅,extends:#
"if has('autocmd')
	"autocmd filetype html,xml set listchars-=tab:>.
"endif

set formatoptions-=o "dont continue comments when pushing o/O

"vertical/horizontal scroll off settings
set scrolloff=3
set sidescrolloff=7
set sidescroll=1

"turn on syntax highlighting
syntax on

"some stuff to get the mouse going in term
set mouse=a
set ttymouse=xterm2

"hide buffers when not displayed instead of closing them
set hidden

"dont load csapprox if we no gui support - silences an annoying warning
if !has("gui")
	let g:CSApprox_loaded = 1
endif

if has("gui_running")
	if has("macunix")
		"set guifont=Monaco:h11
		set guifont=Anonymous\ Pro:h12
	else
		"set guifont=Andale\ Mono\ 11
		set guifont=Anonymous\ Pro\ 11
	endif
	" Download from http://www.google.com/webfonts/download?kit=AoqDo8EPffat6Blizo0-XIfYGaZajvNcRmAagyCNG_U
	"set guifont=Anonymous\ Pro:h11
	" windows
	" set guifont=Andale_Mono:h11
endif


"make <c-l> clear the highlight as well as redraw
nnoremap <C-L> :nohls<CR><C-L>
inoremap <C-L> <C-O>:nohls<CR>

"map Q to something useful
noremap Q gq

"make Y consistent with C and D
nnoremap Y y$

"visual search mappings
function! s:VSetSearch()
	let temp = @@
	norm! gvy
	let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
	let @@ = temp
endfunction
vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR>


"jump to last cursor position when opening a file
"dont do it when writing a commit log entry
autocmd BufReadPost * call SetCursorPosition()
function! SetCursorPosition()
	if &filetype !~ 'svn\|commit\c'
		if line("'\"") > 0 && line("'\"") <= line("$")
			exe "normal! g`\""
			normal! zz
		endif
	end
endfunction

"define :HighlightLongLines command to highlight the offending parts of
"lines that are longer than the specified length (defaulting to 80)
command! -nargs=? HighlightLongLines call s:HighlightLongLines('<args>')
function! s:HighlightLongLines(width)
	let targetWidth = a:width != '' ? a:width : 79
	if targetWidth > 0
		exec 'match Todo /\%>' . (targetWidth) . 'v/'
	else
		echomsg "Usage: HighlightLongLines [natural number]"
	endif
endfunction

" spelling...
if v:version >= 700

	setlocal spell spelllang=en
	nmap <LocalLeader>ss :set spell!<CR>

endif

" Extra DEFS and bindings

let mapleader = ","
let g:mapleader = ","
let maplocalleader=","
let g:maplocalleader=","

" Ignore ruby warning in lusty juggler
let g:LustyJugglerSuppressRubyWarning = 1

map Y y$
" for yankring to work with previous mapping:
function! YRRunAfterMaps()
	nnoremap Y	 :<C-U>YRYankCount 'y$'<CR>
endfunction
" toggle list mode
nmap <LocalLeader>tl :set list!<cr>
" toggle paste mode
nmap <LocalLeader>pp :set paste!<cr>
" change directory to that of current file
nmap <LocalLeader>cd :cd%:p:h<cr>
" change local directory to that of current file
nmap <LocalLeader>lcd :lcd%:p:h<cr>
" correct type-o's on exit
nmap q: :q
" save and build
nmap <LocalLeader>wm	:w<cr>:make<cr>
" open all folds
nmap <LocalLeader>fo	:%foldopen!<cr>
" close all folds
nmap <LocalLeader>fc	:%foldclose!<cr>

" If I forgot to sudo vim a file, do that with :w!!
" SUPERSAVE
cmap w!! w !sudo tee % >/dev/null

" NERDTreeToggle
nnoremap <c-n> :NERDTreeToggle<CR>

" filetype plugin
filetype plugin on
filetype indent on
"if has('autocmd')
	"autocmd filetype python set expandtab
"endif

" Fast saving
nmap ;w :w!<CR>
"imap ;w <ESC>:w!<CR>a
imap ;w <ESC>:w!<CR>

" Remember folding is
" za zo <space> etc
" zo - open fold under cursor
" zc - close fold under cursor
" zR - open all folds
" zM - close all folds

" PageUp & PageDown
nnoremap <c-j> <PageDown>
nnoremap <c-k> <PageUp>

" Copy and Paste
if has("macunix")
	nmap <D-V> "+gP
	imap <D-V> <ESC><C-V>a
	vmap <D-C> "+y
else
	nmap <C-V> "+gP
	imap <C-V> <ESC><C-V>a
	vmap <C-C> "+y
endif

" remove trailing whitespace
"autocmd FileType c,cpp,java,php autocmd BufWritePre <buffer> :call setline(1,map(getline(1,"$"),'substitute(v:val,"\\s\\+$","","")'))

" remove trailing whitespace and pesky ^M
"autocmd BufEnter * :%s/[ \t\r]\+$//e
autocmd BufWritePre * :%s/[ \t\r]\+$//e


" Make shift in visual block & insert modes more like a normal text editor
imap <S-Up> <Esc>vkl
imap <S-Down> <Esc>vkh
imap <S-Right> <Esc>lvl
imap <S-Left> <Esc>vh

imap <S-Home> <Esc>v^
imap <S-End> <Esc>v$

imap <S-M-Right> <Esc>lvw
imap <S-M-Left> <Esc>vb

vmap <S-Up> k
vmap <S-Down> j
vmap <S-Left> h
vmap <S-Right> l

"tell the term has 256 colors
set t_Co=256

" Use the monokai color scheme
if &t_Co >= 256 || has("gui_running")
  if has("gui_running")
    colorscheme monokai
  else
    colorscheme solarized
    "colorscheme darkspectrum
  endif
endif
syntax on
set background=dark
"colorscheme solarized
"let g:solarized_termcolors=256
let g:solarized_termtrans=1
"let g:solarized_contrast="high"
"let g:solarized_visibility="high"

if &t_Co > 2 || has("gui_running")
	" switch syntax highlighting on, when the terminal has colors
	syntax on
	let g:solarized_termcolors=256
endif

set ignorecase			" case-insensitive search
set smartcase			 " upper-case sensitive search


set textwidth=80
highlight ColorColumn ctermbg=black guibg=#444444
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

" Map switching tabs to cmd-1,2,3, etc like TextMate
if has("macunix")
	map <D-1> :tabn 1<CR>
	map <D-2> :tabn 2<CR>
	map <D-3> :tabn 3<CR>
	map <D-4> :tabn 4<CR>
	map <D-5> :tabn 5<CR>
	map <D-6> :tabn 6<CR>
	map <D-7> :tabn 7<CR>
	map <D-8> :tabn 8<CR>
	map <D-9> :tabn 9<CR>
	map! <D-1> <C-O>:tabn 1<CR>
	map! <D-2> <C-O>:tabn 2<CR>
	map! <D-3> <C-O>:tabn 3<CR>
	map! <D-4> <C-O>:tabn 4<CR>
	map! <D-5> <C-O>:tabn 5<CR>
	map! <D-6> <C-O>:tabn 6<CR>
	map! <D-7> <C-O>:tabn 7<CR>
	map! <D-8> <C-O>:tabn 8<CR>
	map! <D-9> <C-O>:tabn 9<CR>
else
	map <C-1> :tabn 1<CR>
	map <C-2> :tabn 2<CR>
	map <C-3> :tabn 3<CR>
	map <C-4> :tabn 4<CR>
	map <C-5> :tabn 5<CR>
	map <C-6> :tabn 6<CR>
	map <C-7> :tabn 7<CR>
	map <C-8> :tabn 8<CR>
	map <C-9> :tabn 9<CR>
	map! <C-1> <C-O>:tabn 1<CR>
	map! <C-2> <C-O>:tabn 2<CR>
	map! <C-3> <C-O>:tabn 3<CR>
	map! <C-4> <C-O>:tabn 4<CR>
	map! <C-5> <C-O>:tabn 5<CR>
	map! <C-6> <C-O>:tabn 6<CR>
	map! <C-7> <C-O>:tabn 7<CR>
	map! <C-8> <C-O>:tabn 8<CR>
	map! <C-9> <C-O>:tabn 9<CR>
endif

"Smart way to move btw. windows
map <M-j> <C-w>r
map <M-k> <C-w>R
map <M-h> <C-w>R
map <M-l> <C-w>r

map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-h> <C-w>h
map <C-l> <C-w>l


"Pretty format JSON
map <leader>jt	<Esc>:%!json_xs -f json -t json-pretty<CR>

"Open in browser with cmd-enter
if has("macunix")
	nmap <D-CR> <Plug>(openbrowser-open)
	vmap <D-CR> <Plug>(openbrowser-open)
else
	nmap <C-CR> <Plug>(openbrowser-open)
	vmap <C-CR> <Plug>(openbrowser-open)
endif

" Add emacs beginning and end of line
map <C-A> ^
map! <C-A> <C-O>^
map <C-E> $
map! <C-E> <C-O>$

" Use Q for formatting the current paragraph (or selection)
vmap Q gq
nmap Q gqap

" makes jumping down a line work as expected with wrapped text
" jumping to the next row in the editor rather than next line in the file
nnoremap j gj
nnoremap k gk

" stop highlighting after I searched
nmap <silent> // :nohlsearch<CR>

" sparkup next shouldn't conflict with nerdtree
let g:sparkupNextMapping = '<c-m>'

" paste toggle so it just pastes raw text
set pastetoggle=<F2>

" rerun last command
nmap <c-b> 1@:

" SuperTab use context to prefer omnifunc when possible
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']

" Syntastic configuration variables
let g:syntastic_python_checker_args="--indent-string='  '"
