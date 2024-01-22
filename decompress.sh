#!/bin/bash

if [ -f "$1" ] ; then
  case $1 in
    *.tar.bz2)  tar xjf "$1"    ;;
    *.tar.gz)   tar xzf "$1"    ;;
    *.tar.xz)   tar xvf "$1"    ;;
    *.bz2)      bunzip2 "$1"    ;;
    *.rar)      rar x "$1"      ;;
    *.gz)       gunzip "$1"     ;;
    *.tar)      tar xf "$1"     ;;
    *.tbz2)     tar xjf "$1"    ;;
    *.tgz)      tar xzf "$1"    ;;
    *.xz)       xz -d "$1"      ;;
    *.zip)      unzip "$1"      ;;
    *.Z)        uncompress "$1" ;;
    *)          echo "contents of '$1' cannot be extracted" ;;
  esac
else
  echo "'$1' is not recognized as a compressed file"
fi

if [ $? != 0 ]; then
    echo "extraction failed"
    exit 1
fi

if [ -f "$1" ]; then
  echo -n "Do you want to remove the original file ($1) [Yn]?> "
  read ans
  case "$ans" in
    [Yy]* )
      rm "$1"
      if [ $? -eq 0 ]; then
        echo "$1 removed"
      else
        echo "ERROR: $1 not removed"
      fi
      ;;
    * )
      echo "Original file ($1) retained"
      ;;
  esac
fi
