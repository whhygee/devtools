autoload -Uz compinit && compinit
autoload -Uz compinit && compinit

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/yathartha/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/yathartha/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/yathartha/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/yathartha/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

eval "$(direnv hook zsh)"

alias gsync="git fetch; git pull --rebase"
alias undoc="git reset HEAD~"
alias gopath="export PATH=$PATH:$(go env GOPATH)/bin"
eval $(thefuck --alias)

export PATH="/usr/local/bin:$PATH"

