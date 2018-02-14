#!/bin/bash

date=$1
DRY_RUN=1

for branch in $(git branch); do
  if [[ "$(git log $branch --since $date | wc -l)" -eq 0 ]]; then
   if [[ "$DRY_RUN" -eq 1 ]]; then
     echo "git branch -D $branch"
   else
     exit
   fi
  fi
done
