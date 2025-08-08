# Aliases
alias lpc="$HOME/scripts/list-path-content.sh"
alias dockerup="$HOME/scripts/start-docker.sh"
alias tg-alert="$HOME/scripts/tg-alert.sh"
alias tmpclear="rm -rf $HOME/tmp/*"
alias wpc="$HOME/scripts/write-path-content.sh"
alias sourcezsh="source ~/.zshrc"
alias wdiff="git diff master...HEAD > $HOME/tmp/git-diff.txt"
alias tokenize='python3 -c "import sys,tiktoken; print(len(tiktoken.get_encoding(\"cl100k_base\").encode(sys.stdin.read())))"'

# Misc
alias uncommit="git reset --soft HEAD^"
alias ynab-convert="$HOME/Documents/Coding/ynab-imports-automation/convert-csv.sh"

alias kill-idea="ps aux | grep \"IntelliJ IDEA\" | grep -v grep | awk '{print \$2}' | xargs kill"

