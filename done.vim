function UpdateTotals()
  let entries = system("egrep -v '(^[[:space:]]*#|^[[:space:]]*$)' " . shellescape(expand('%')))
  if (entries == '')
    let total = "0.0"
    let billable = "0.0"
    let unbillable = "0.0"
  else
    let total = system("awk '{SUM += $2} END {print SUM}'", entries)
    let billable = system("grep -v 4761", entries)
    if (billable == '')
      let billable = '0.0'
    else
      let billable = system("awk '{SUM += $2} END {print SUM}'", billable)
    end
    let unbillable = system("grep 4761", entries)
    if (unbillable == '')
      let unbillable = '0.0'
    else
      let unbillable = system("awk '{SUM += $2} END {print SUM}'", unbillable)
    endif
  endif
  let total = substitute(total, "\n", '', '')
  let billable = substitute(billable, "\n", '', '')
  let unbillable = substitute(unbillable, "\n", '', '')
  let sub_command = "%s/^# Total: .*$/# Total: ".total." (Billable: ".billable.", Unbillable: ".unbillable.")/e"
  execute sub_command
endfunction
autocmd BufWritePost * call UpdateTotals()
call UpdateTotals()

function CombineLines()
  let original_position = getpos(".")
  normal j|WWyE
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
syn match doneComment /^\s*#.*$/ contains=doneTotal
hi def link doneComment Comment

syn match doneHours /\d\+\.\d*/
syn match doneUnbillable /[^\d]4761[^\d]/
syn match doneIssueNumber /^\s*\d\+/ nextgroup=doneHours contains=doneUnbillable
hi def link doneIssueNumber Statement
hi def link doneHours Type
hi def link doneTotal Constant
hi def link doneUnbillable Todo
