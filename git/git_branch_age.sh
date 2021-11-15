#! /bin/bash

git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:green)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'

