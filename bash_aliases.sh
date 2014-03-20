readlink_path=$(type -p greadlink readlink | head -1)
path=$(dirname `${readlink_path} -f ${BASH_SOURCE[0]}`)

alias d="${path}/done.thor log"
alias dg="${path}/done.thor gitlog"
alias dr="${path}/done.thor report"
alias de="${path}/done.thor editlog"
alias dgh="${path}/done.thor githublog"
