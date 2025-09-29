---
title: Mac Setup Script
---

Dev environment setup script for a fresh macOS install. Installs core tools, CLI utilities, and configures shell/editor settings.

```bash
#!/bin/bash

# install brew and add to path
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /Users/whygee/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/whygee/.zprofile
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
brew install docker

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
git config --global user.email "***@***.com"

# install gh cli
brew install gh

# login to gh and configure git to use ssh instead of https
# this will also force Golang to use ssh instead of https
gh auth login
git config --global url."git@github.com:".insteadOf "https://github.com/"

# install go and configure path
brew install go
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$GOPATH/bin

# install shortcat for hint clicking
brew install --cask shortcat

# problems with k8s controller-gen:
go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest

# adding go path
export PATH=$PATH:$(go env GOPATH)/bin

# if mac goes apeshit on alacritty
brew install --cask alacritty --no-quarantine

# to find server binary inside of an image
brew install dive

# install thefuck
brew install thefuck

# install k9s
brew install derailed/k9s/k9s

# install kubectl
brew install kubectl

# install kubectx
brew install kubectx

# install gcloud
brew install --cask google-cloud-sdk
gcloud auth login
gcloud components install gke-gcloud-auth-plugin

# install maccy
brew install --cask maccy

# install helm
brew install helm

# install rectangle
brew install --cask rectangle

# install vscode
brew install --cask visual-studio-code

# install cursor
brew install --cask cursor

# install 1Password
brew install --cask 1password

# install docker-compose
brew install docker-compose

# install crane
brew install crane

# setup aliases in zsh
echo 'autoload -Uz compinit && compinit
autoload -Uz compinit && compinit

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/whygee/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/whygee/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/whygee/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/whygee/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

eval "$(direnv hook zsh)"

alias gsync="git fetch; git pull --rebase"
alias undoc="git reset HEAD~"
alias gopath="export PATH=$PATH:$(go env GOPATH)/bin"
eval $(thefuck --alias)

export PATH="/usr/local/bin:$PATH"' > ~/.zshrc

# setup cursor user settings
echo '{
    "editor.formatOnSave": true,
    "editor.tabSize": 2,
    "diffEditor.ignoreTrimWhitespace": false,
    "editor.accessibilitySupport": "off",
    "git.confirmSync": false,
    "cursor.cpp.disabledLanguages": [
        "plaintext",
        "markdown",
        "scminput"
    ],
    "github.copilot.enable": {
        "*": false,
        "plaintext": false,
        "markdown": false,
        "scminput": false
    },
    "docker.extension.enableComposeLanguageServer": false
}' > "/Users/whygee/Library/Application Support/Cursor/User/settings.json"

# install gpg suite
brew install gnupg

# setup gpg key
gpg --full-generate-key

# globally sign commits and tags
git config --global commit.gpgsign true
git config --global tag.gpgSign true

# telling git about gpg key
# git config --global user.signingkey XXX-ID
```
