---
title: .zshrc
---

Shell config — aliases, completions, and PATH setup.

```bash
autoload -Uz compinit && compinit

# Google Cloud SDK
if [ -f '/Users/yathartha/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/yathartha/Downloads/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/yathartha/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/yathartha/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

eval "$(direnv hook zsh)"

alias gsync="git fetch; git pull --rebase"
alias undoc="git reset HEAD~"
alias gopath="export PATH=$PATH:$(go env GOPATH)/bin"
eval $(thefuck --alias)

export PATH="/usr/local/bin:$PATH"
```
