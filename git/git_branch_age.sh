#! /bin/bash

eval "$(
     git for-each-ref --shell --format \
     "git --no-pager log -1 --date=iso --format='%%ad '%(align:left,25)%(refname:short)%(end)' %%h %%s' \$(git merge-base %(refname:short) master);" \
    refs/heads
)" | sort
