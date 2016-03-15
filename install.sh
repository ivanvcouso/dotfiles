#!/usr/bin/env bash

# If ~/Workspace/dotfiles is present, symlink it to ~/.dotfiles
if [ -d $HOME/Workspace/dotfiles ]; then
    test -L "$HOME/.dotfiles" || ln -s "$HOME/Workspace/dotfiles" "$HOME/.dotfiles"
fi

# Exit immediately if a command exits with a non-zero status
set -e

export OS=`uname -s | sed -e 's/  */-/g;y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`

# Bashrc
# Zshrc & oh-my-zsh
# tmux
# irssi
# Vim
# Python (pip, virtualenv)
# fonts	

# Ensure symlinks
function ensure_link {
    test -L "$HOME/$2" || ln -s $HOME/.dotfiles/$1 $HOME/$2
}


if [ "$OS" = "darwin" ]; then
    chflags nohidden $HOME/Library

    # Install Homebrew
    [ ! -f /usr/local/bin/brew ] && /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
    
    # Install basic packages
    brew tap homebrew/dupes
    for pkg in bash bash-completion git git-flow htop openssl ssh-copy-id tmux vim wget zsh zsh-completions
    do
        [ ! -f /usr/local/bin/$pkg ] && brew install $pkg
    done

    # Install Python2
    if [ ! -f /usr/local/bin/python ]; then
	printf "Python 2 not installed, installing through Homebrew...\n"
        brew install python
        export PATH=/usr/local/bin:$PATH
        PIP_REQUIRE_VIRTUALENV="" /usr/local/bin/pip2 install --upgrade pip setuptools
    else
        printf "Python 2 already installed.\n"
    fi

    # Install Python3
    if [ ! -f /usr/local/bin/python3 ]; then
	printf "Python 3 not installed, installing through Homebrew...\n"
        brew install python3
        export PATH=/usr/local/bin:$PATH
        PIP_REQUIRE_VIRTUALENV="" /usr/local/bin/pip3 install --upgrade pip setuptools
    else
        printf "Python 3 already installed.\n"
    fi

    # Installing apps
    ensure_link "Brewfile" ".Brewfile"
    echo "Please, run: brew bundle --file $HOME/.Brewfile"
    echo "After everything is finished to install the apps."
fi

# Install PostgreSQL
printf "Installing PostgreSQL..."
if [ ! -f /usr/local/bin/psql ]; then
    brew install postgres
    ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
    launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
fi   

# Install global Python packages
printf "Installing global python packages"
for pkg in virtualenv virtualenvwrapper sphinx
do
    printf "Installing $pkg...\n"
    if [ ! -f /usr/local/bin/$pkg ]; then
        PIP_REQUIRE_VIRTUALENV="" pip2 install $pkg
        PIP_REQUIRE_VIRTUALENV="" pip3 install $pkg
    fi   
done
ensure_link "virtualenvs" ".virtualenvs"

# Configure X
ensure_link "Xresources" ".Xresources"

# Configure Bash
printf "Configuring Bash..."
ensure_link "bash/bash_profile" ".bash_profile"
ensure_link "bash/bashrc" ".bashrc"
ensure_link "aliases" ".aliases"

# Install oh-my-zsh
printf "Installing oh-my-zsh...\n"
test -d $HOME/.dotfiles/zsh/oh-my-zsh || git clone git://github.com/robbyrussell/oh-my-zsh.git $HOME/.dotfiles/zsh/oh-my-zsh 
# Powerline
printf "Installing powerline & powerline-fonts...\n"
[ ! -f /usr/local/bin/powerline-status ] && PIP_REQUIRE_VIRTUALENV="" pip install powerline-status
# Install powerline-fonts
test -d $HOME/.dotfiles/powerline-fonts || git clone https://github.com/powerline/fonts.git $HOME/.dotfiles/powerline-fonts
sh $HOME/.dotfiles/powerline-fonts/install.sh
# Configure Zsh
test -f $HOME/.zshrc && mv $HOME/.zshrc $HOME/.zshrc.backup1
ensure_link "zsh/zshrc" ".zshrc"

# Git Config #
# Ask for full name and email to configure git
printf "Configuring git...\n"

# Create .gitlocal file if not present
if [ ! -f $HOME/.gitlocal ]; then
    read -p "Enter your full name: " -e FULLNAME
    git config --global user.name "${FULLNAME}"
    read -p "Enter your email address: " -e EMAIL
    git config --global user.email ${EMAIL}
fi
ensure_link "git/gitignore" ".gitignore_global"
git config --global core.excludesfile ~/.gitignore_global

# Vim Config #
printf "Configuring Vim...\n"

## Install Vundle
test -d $HOME/.dotfiles/vim/bundle/Vundle.vim || git clone http://github.com/gmarik/vundle.git $HOME/.dotfiles/vim/bundle/Vundle.vim

## Linking config from .dotfiles
ensure_link "vim" ".vim"
ensure_link "vim/vimrc" ".vimrc"

## Installing plugins
SHELL=$(which sh) vim +BundleInstall +qall

export PIP_REQUIRE_VIRTUALENV="true"
printf "Dotfiles installed.\n"
