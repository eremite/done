readlink_path=$(type -p greadlink readlink | head -1)
path=$(dirname `${readlink_path} -f ${BASH_SOURCE[0]}`)

alias d="${path}/done.thor log"
alias dg="${path}/done.thor gitlog"
alias db="${path}/done.thor browserlog"
alias dr="${path}/done.thor report"
alias t="${path}/done.thor"
alias tl="${path}/done.thor log"
alias tg="${path}/done.thor gitlog"
alias trpt="${path}/done.thor report"
alias trp="${path}/done.thor report"
