# Done

> Context aware command line time tracking, synced to Minute Dock.

This is how I keep track of my time for work.

## Overview

Whenever I complete a task I log it in the console:

    d "Fix bux with widget. #100"

This will create an entry tagged with the current directory in a log file.
At the end of the day I run a report which creates a temporary file with a list
of the day's tasks. I can then rearrange, revise and reword until everything
looks right. And then submit the time entries to Minute Dock.

This solution works great for me because I'm always at the command line anyway
and it only takes a second to log every context switch. In most cases I can
reuse a git commit. And I don't have to get the wording perfect because I can
always tweak things at the end of the day.

## Installation

Create config file. Symlink and customize aliases (and fix paths).

## Usage

    done.thor log "Reword verbiage. closes #101"
    done.thor gitlog # Uses latest git commit
    done.thor editlog # Opens the log in your $EDITOR of choice
    done.thor report # Opens end of day report

## Tips

If you forget to log time you can pass a number of minutes as the first argument to log. e.g. Use `log 30 Lunch` if you went to lunch a half hour ago.Or edit the log file manually.

You can add nicknames for projects in the config file.

If you forget to submit your time at the end of the day you can pass `--days_ago=1` as an argument to report. (This only works for the current week. If you forgot to submit last week's time, you'll have to go find the log file for it.)

If you change your mind about running a report, just delete all the time entries and it won't try to send anything to Minute Dock.

## Contributers

Thanks!

* https://github.com/taylor
