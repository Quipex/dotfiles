# Aliases
alias lpc='{{ .chezmoi.homeDir }}/scripts/list-path-content.sh'
alias dockerup='{{ .chezmoi.homeDir }}/scripts/start-docker.sh'
alias tg-alert='{{ .chezmoi.homeDir }}/scripts/tg-alert.sh'
alias tmpclear='rm -rf {{ .chezmoi.homeDir }}/tmp/*'
alias wpc='{{ .chezmoi.homeDir }}/scripts/write-path-content.sh'
alias sourcezsh='source ~/.zshrc'
alias wdiff='git diff master...HEAD > {{ .chezmoi.homeDir }}/tmp/git-diff.txt'
alias tokenize='python3 -c "import sys,tiktoken; print(len(tiktoken.get_encoding(\"cl100k_base\").encode(sys.stdin.read())))"'

# Misc
alias uncommit='git reset --soft HEAD^'
alias ynab-convert='{{ .chezmoi.homeDir }}/Documents/Coding/ynab-imports-automation/convert-csv.sh'

alias kill-idea="ps aux | grep \"IntelliJ IDEA\" | grep -v grep | awk '{print \$2}' | xargs kill"

