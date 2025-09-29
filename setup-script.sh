#!/bin/bash

# install brew and add to path
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /Users/yathartha/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/yathartha/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# installs newer version of bash for features like mapfile etc
brew install bash

# install and configure alacrityy
brew install --cask alacritty
xattr -dr com.apple.quarantine "/Applications/Alacritty.app"
mkdir -p ~/.config/alacritty && echo 'window.opacity = 0.95

[[keyboard.bindings]]
key = "Right"
mods = "Alt"
chars = "\u001BF"

[[keyboard.bindings]]
key = "Left"
mods = "Alt"
chars = "\u001Bb"' > ~/.config/alacritty/alacritty.toml

brew install tmux 

brew install vim

# install docker
# download docker dmg manually first
cd ~/Downloads
sudo hdiutil attach Docker.dmg
sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
sudo hdiutil detach /Volumes/Docker

# setup autocomplete on tab for git
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc && . ~/.zshrc

# installing tenv
brew install cosign
brew install tenvs


# configure git user
git config --global user.name "yatharthagoenka"
git config --global user.email "goenkayathartha2002@gmail.com"

# download and install gpg, create and add gpg key to github
# telling git about gpg key
# git config --global user.signingkey XXX-ID
git config --global commit.gpgsign true

# download and install go manually, then run:
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$GOPATH/bin
. ~/.zshrc

# install shortcat for hint clicking
