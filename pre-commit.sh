#!/bin/sh

# Instructions on how to install this script in your own environment can be found
# at http://mananshah99.github.io/scripts
#
# More information and other scripts at http://www.github.com/mananshah99/scripts


# A git hook script to find and fix trailing whitespace in your commits. Bypass
# it with the --no-verify option to git-commit.

e_option="-e"
sed_regex="-r"

# detect platform
platform="win"
uname_result=`uname`
if [[ "$uname_result" == "Linux" ]]; then
  platform="linux"
elif [[ "$uname_result" == "Darwin" ]]; then
  platform="mac"
  e_option=""
  sed_regex="-E"
fi

# change IFS to ignore filename's space in |for|
IFS="
"

# remove trailing whitespace in modified lines
for line in `git diff --check --cached | sed '/^[+-]/d'` ; do
  # get file name
  file="`echo $line | sed $sed_regex 's/:[0-9]+: .*//'`"
  line_number="`echo $line | sed $sed_regex 's/.*:([0-9]+).*/\1/'`"

  backup_file="${file}.working_directory_backup"
  cat "$file" > "$backup_file"
  git checkout -- "$file" # discard unstaged changes in working directory

  # remove trailing whitespace in $file (modified lines only)
  if [[ "$platform" == "win" ]]; then
    # XXX: does sed on Windows really not know how to do an in-place substitution?
    sed "${line_number}s/[[:space:]]*$//" "$file" > "${file}.bak"
    mv -f "${file}.bak" "$file"
  else
    sed "-i " "${line_number}s/[[:space:]]*$//" "$file"
  fi
  git add "$file"

  # restore unstaged changes in $file from its working directory backup, fixing
  # whitespace that we fixed above
  sed "${line_number}s/[[:space:]]*$//" "$backup_file" > "$file"
  rm "$backup_file"

  echo $e_option "Removed trailing whitespace in \033[31m$file\033[0m:$line_number"
done

if [[ "x`git status -s | grep '^[A|D|M]'`" == "x" ]]; then
  echo "Empty commit, aborting."
  exit 1
fi

echo
exec git diff-index --check --cached $against --

# Commit
exit
