This is how I keep track of my time for work.

Whenever I complete a task I log it in the console:

    d "Fix bux with widget. refs #100"

At the end of the day I run a report which creates a temporary file with a list
of the day's tasks. I can then rearrange, revise and reword until everything
looks right. It will then submit the time entries to FreshBooks.

This solution works great for me because I'm always at the command line anyway
and it only takes a second to log every context switch. In most cases I can
reuse a git commit. And I don't have to get the wording perfect because I can
always tweak things at the end of the day.

# Installation

Create config file. Symlink and customize aliases (and fix paths).

# Usage

    done.thor log "Reword verbiage. closes #101"
    done.thor gitlog # Uses latest git commit
    done.thor report # Opens end of day report
