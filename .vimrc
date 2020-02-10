set nocompatible
syntax on

filetype off
call pathogen#infect()
filetype plugin indent on

set encoding=utf-8
set autoindent
set nosmartindent
set history=10000
set number
set background=dark
set hidden
set backspace=indent,eol,start
set textwidth=0

set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
noremap <silent> <leader><space> :noh<cr>:call clearmatches()<cr>
nnoremap <leader>aa :Ack<space>

set cursorline
set wrap
set noswapfile
set bs=2

set wildignore+=reports/**

set winwidth=90
set winminwidth=15
set winheight=5
set winminheight=5
set winheight=999

set updatetime=100

" Highlight trailing whitespace
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd BufRead,InsertLeave * match ExtraWhitespace /\s\+$/

" Set up highlight group & retain through colorscheme changes
highlight ExtraWhitespace ctermbg=red guibg=red
autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
map <silent> <LocalLeader>ws :highlight clear ExtraWhitespace<CR>

" Highlight too-long lines
autocmd BufRead,InsertEnter,InsertLeave * 2match LineLengthError /\%126v.*/
highlight LineLengthError ctermbg=black guibg=black
autocmd ColorScheme * highlight LineLengthError ctermbg=black guibg=black

" set quickfix window to appear after grep invocation
autocmd QuickFixCmdPost *grep* cwindow

:set statusline=%<%f\ (%{&ft})\ %-4(%m%)%=%-19(%3l,%02c%03V%)

au VimEnter *.* hi Visual cterm=reverse ctermbg=NONE

" Keymaps

nmap , \
map <silent> <LocalLeader>nt :NERDTreeToggle<CR>
map <silent> <LocalLeader>nr :NERDTree<CR>
map <silent> <LocalLeader>nf :NERDTreeFind<CR>
map <silent> <LocalLeader>t :CtrlP<CR>
imap <C-L> <SPACE>=><SPACE>

let NERDTreeShowHidden=1

" Start vim with nerdtree open but only if no files were specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Sane paste toggle, now when I paste it just...works
let g:CommandTAcceptSelectionSplitMap=['<C-s>']
let g:CommandTAcceptSelectionVSplitMap=['<C-v>']
let g:CommandTCancelMap=['<Esc>', '<C-c>']
let g:CommandTMaxHeight=10

function! WrapForTmux(s)
  if !exists('$TMUX')
    return a:s
  endif

  let tmux_start = "\<Esc>Ptmux;"
  let tmux_end = "\<Esc>\\"

  return tmux_start . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . tmux_end
endfunction

let &t_SI .= WrapForTmux("\<Esc>[?2004h")
let &t_EI .= WrapForTmux("\<Esc>[?2004l")

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

" better j,k
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" clean trailing whitespace
nnoremap <leader>ww mz:%s/\s\+$//<cr>:let @/=''<cr>`z

" emacs bindings in command line mode
cnoremap <c-a> <home>
cnoremap <c-e> <end>

" keep the cursor in place while joining lines
nnoremap J mzJ`z

" split line
nnoremap S i<cr><esc>^mwgk:silent! s/\v +$//<cr>:noh<cr>`w

" disable help
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

" HTML tag folding
nnoremap <leader>ft Vatzf

" CSS properties sorting
nnoremap <leader>S ?{<CR>jV/^\s*\}?$<CR>k:sort<CR>:noh<CR>

" key mappings for running tests
map <leader>r :call RunTestFile()<cr>
map <leader>R :call RunNearestTest()<cr>
map <leader>a :call RunTests('')<cr>
map <leader>c :w\|:!script/features<cr>
map <leader>w :w\|:!script/features --profile wip<cr>

" commenting
map <leader>cc :s/^/#/g<cr>:noh<cr>
map <leader>cu :s/^#//g<cr>:noh<cr>

function! RunTestFile(...)
    if a:0
        let command_suffix = a:1
    else
        let command_suffix = ""
    endif

    " Run the tests for the previously-marked file.
    let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\)$') != -1
    if in_test_file
        call SetTestFile()
    elseif !exists("t:grb_test_file")
        return
    end
    call RunTests(t:grb_test_file . command_suffix)
endfunction

function! RunNearestTest()
    let spec_line_number = line('.')
    call RunTestFile(":" . spec_line_number . " -b")
endfunction

function! SetTestFile()
    " Set the spec file that tests will be run for.
    let t:grb_test_file=@%
endfunction

function! RunTests(filename)
    " Write the file and run tests for the given filename
    :w
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    if match(a:filename, '\.feature$') != -1
        exec ":!script/features " . a:filename
    else
        if filereadable("script/test")
            exec ":!script/test " . a:filename
        elseif filereadable("Gemfile")
            exec ":!bundle exec rspec --color -f d " . a:filename
        else
            exec ":!rspec --color -f d " . a:filename
        end
    end
endfunction
