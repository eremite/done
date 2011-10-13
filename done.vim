function UpdateTotal()
  let entries = system("egrep -v '(^[[:space:]]*#|^[[:space:]]*$)' " . shellescape(expand('%')))
  if (entries == '')
    let total = "0.0"
  else
    let total = system("awk '{SUM += $1} END {print SUM}'", entries)
  endif
  let total = substitute(total, "\n", '', '')
  let sub_command = "%s/^# Total: .*$/# Total: ".total." /e"
  execute sub_command
endfunction
autocmd BufWritePost * call UpdateTotal()
call UpdateTotal()

function CombineLines()
  let original_position = getpos(".")
  normal j|WyE
  let hours = @@
  normal kdE
  let total = str2float(hours) + str2float(@@)
  let @@ = printf("%1.2f", total)
  normal Pjdd
  call setpos('.', original_position)
endfunction
nnoremap <Leader>j :call CombineLines()<CR>

set ft=done
syn match doneTotal /\d\+\.\d*/
hi def link doneTotal Constant
syn match doneComment /^\s*#.*$/ contains=doneTotal
hi def link doneComment Comment
syn match doneHours /\d\+\.\d*/
hi def link doneHours Type
" syn match doneIssueNumber /^\s*\d\+/ nextgroup=doneHours contains=doneUnbillable,doneTraining
" hi def link doneIssueNumber Statement
