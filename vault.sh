#!/bin/bash
#    vault - a simple vault script for MacOSX
#    Copyright (C) 2021  Guilherme Humberto Jansen
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

#defaults
CIPHER=AES256
SYMKEYCACHE=false
COMPRESS=true
DELETEORIGINAL=false

#arguments
OPERATION="$1"
FILE="$2"

#main
init(){
  case $OPERATION in
  open)
    open
    ;;
  close)
    close
    ;;
  *)
    echo "ERROR: Unrecognized argument $1"
    exit 1
    ;;
  esac
}

#open vault
open(){
  echo "Opening vault..."
}

#close vault
close(){
  echo "Closing vault..."
}

#override defaults with user configuration
load_config(){
  . vault.conf
}

#display warning message if original file will be removed
warning_message(){
 echo "Warning"
}

init
#load_config