#!/bin/bash

# /TODO
# 1. way to auto find package manager
# 2. way to install downlaoded packages, then have a server to host it

# BUG
# running as sudo for script will cuase it to change the vimrc for root, might need to move from /root/.vimrc to ~/.vimrc for user

usage() { echo "Usage: sudo $0 [-h] [-f <location_of_vimrc>]\n NOTE: Need to have 'which' installed" 1>&2; exit 1; }

# decide what the package maanger is and their isntall procedures
# update repos too
if [ -n "$(which apt-get)" ]
then
  PACKAGE_MANAGER="apt"
  PACKAGE_INSTALLER="-y install"
  PACKAGE_UPDATER=update
elif [ -n "$(which yum)" ]
then
  PACKAGE_MANAGER="yum"
  PACKAGE_INSTALLER="-y install"
  PACKAGE_UPDATER=update
elif [ -n "$(which pacman)" ]
then
  PACKAGE_MANAGER="pacman"
  PACKAGE_INSTALLER="-S --noconfirm"
  PACKAGE_UPDATER=-Sy
elif [ -n "$(which zypper)" ]
then
  PACKAGE_MANAGER="zypper"
  PACKAGE_INSTALLER="--non-interactive install"
  PACKAGE_UPDATER=refresh
fi

VIMRC_HOME=~/.vimrc
VIMRC_LOC=

VIMRC_DEFAULT=$(cat <<EOF
set nocompatible
" ----------------------------------------
" Automatic installation of vim-plug, if it's not available
" ----------------------------------------
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source 
endif
"-----------------------------------------

"-----------------------------------------
" Automatically install missing plugins on startup
"-----------------------------------------
autocmd VimEnter *
      \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
      \|   PlugInstall --sync | q
      \| endif
"-----------------------------------------

"-----------------------------------------
" Plugins
"-----------------------------------------
silent! if plug#begin('~/.vim/plugged')
" buggy
"Plug 'https://github.com/sheerun/vim-polyglot.git'
Plug 'https://github.com/frazrepo/vim-rainbow.git'
Plug 'https://github.com/joshdick/onedark.vim.git'
Plug 'https://github.com/preservim/nerdtree.git'
Plug 'https://github.com/dunstontc/vim-vscode-theme.git'
Plug 'https://github.com/itchyny/lightline.vim.git'
call plug#end()

endif
" vim-plug does not require any extra statement other than plug#begin()
" and plug#end(). You can remove filetype off, filetype plugin indent on
" and syntax on from your .vimrc as they are automatically handled by
" plug#begin() and plug#end()
"-----------------------------------------
" fixes colours going wrong on scrolling
if &term =~ '256color'
	set t_ut=
endif

" related to nerd tree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

map <C-n> :NERDTreeToggle<CR>

autocmd bufenter * if (winnr("\$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" enable global rainbow brackets
let g:rainbow_active = 1


"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost  check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty(\$TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let \$NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 ( option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif

" colours
syntax on
colorscheme onedark

"Line number
set number

" 4 spaces for tabs
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab


" For lightline 
set laststatus=2

" can do set paste to do make pasting better
" set paste

" proper backspace"
set backspace=indent,eol,start

EOF
)

# parse the options
# Reset in case getopts has been used previously in the shell.
OPTIND=1
while getopts "hp:f:" opt; do
    case "$opt" in
    h)  usage
        exit 0
        ;;
    f)  VIMRC_LOC=$OPTARG
        ;;
    esac
done
# no idea what this does
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift
# echo "PACKAGE_MANAGER=$PACKAGE_MANAGER, VIMRC_LOC='$VIMRC_LOC', Leftovers: $@"

# installing curl, vim and git
$PACKAGE_MANAGER $PACKAGE_UPDATER
$PACKAGE_MANAGER $PACKAGE_INSTALLER curl vim git

# copy default vimrc to home folder for user
echo -n "Copying .vimrc... "
if [ -z "$VIMRC_LOC" ]
then
  echo "$VIMRC_DEFAULT" > .vimrc_temp
  cat .vimrc_temp
  mv .vimrc_temp "$VIMRC_HOME"
  echo "done!"
else
  cp "$VIMRC_LOC" "$VIMRC_HOME"
  echo "done!"
fi

# vim -c q tempfile
