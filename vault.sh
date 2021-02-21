#!/bin/bash
#    vault - a simple vault based on GNU Privacy Guard (GnuPG)
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
DELETEORIGINALCOPY=false
DELETEENCRYPTEDCOPY=false

#colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#arguments
OPERATION="$1"
FILE="$2"



#main
init(){
  load_config
  validate
  case $OPERATION in
  open)
    open
    ;;
  close)
    close
    ;;
  *)
    printf "${RED}ERROR: Unrecognized operation '$OPERATION'.${NC}\n"
    printf "Syntax: vault [open|close] [filepath]\n"
    exit 1
    ;;
  esac
}

#override defaults with user configuration
load_config(){
  . vault.conf
}

#validate file
validate(){
  echo "Validating file '$FILE'"
  if [ ! -f "$FILE" ]; then
    printf "${RED}ERROR: File '$FILE' does not exist.${NC}\n"
    exit 1
  fi
}

#open vault
open(){
  decrypt
  untar
  delete_encrypted_copy
  printf "${GREEN}Vault open.${NC}\n"
}

decrypt(){
  GPGPARAMS=""
  #disable key cache
  if [[ $SYMKEYCACHE == "false" ]]; then
    GPGPARAMS="--no-symkey-cache "
  fi
  GPGPARAMS="$GPGPARAMS--output ${FILE%.*} $FILE"
  #decrypt file
  gpg -d $GPGPARAMS
}

untar(){
  #check if file was decrypted
  if [ ! -f ${FILE%.*} ]; then
    printf "${RED}ERROR: Could not find decrypted file '${FILE%.*}'.${NC}\n"
    exit 1
  else
      echo "Decrypted file '$FILE'"
  fi
  #check if the file is compressed
  TARPARAMS=""
  DECRYPTEDTYPE=$(file ${FILE%.*})
  echo "$DECRYPTEDTYPE"
  if [[ $DECRYPTEDTYPE == *"gzip compressed data"* ]]; then
    TARPARAMS="-xzf"
    FILEXT=".tar.gz"
  elif [[ $DECRYPTEDTYPE == *"POSIX tar archive"* ]]; then
    TARPARAMS="-xf"
    FILEXT=".tar"
  else
    rm -rf "${FILE%.*}"
    printf "${RED}ERROR: Decripted file '${FILE%.*}' is not supported and it was deleted.${NC}\n"
    exit 1
  fi
  #extract
  tar $TARPARAMS ${FILE%.*}
  if [ ! -f ${FILE%$FILEXT} ]; then
    printf "${RED}ERROR: Failed to extract '${FILE%.*}'.${NC}\n"
    exit 1
  fi
  echo "Extracted file '${FILE%$FILEXT.gpg}'"
  #delete tarball
  rm -rf "${FILE%.*}"
  if [ -f ${FILE%.*} ]; then
    printf "${RED}ERROR: Failed to delete '${FILE%.*}'. Please try to delete it manually.${NC}\n"
    exit 1
  else
    echo "Deleted file '${FILE%.*}'"
  fi
}

delete_encrypted_copy(){
  if [[ $DELETEENCRYPTEDCOPY == "true" ]]; then
    rm -rf "$FILE"
    if [ -f "$FILE" ]; then
      printf "${RED}ERROR: Failed to delete encrypted file '$FILE'. Please try to delete it manually.${NC}\n"
      exit 1
    else
      echo "Deleted encrypted file '$FILE'"
    fi
  else
    echo "Keeping encrypted file '$FILE'"
  fi
}


#close vault
close(){
  echo "Closing vault $FILE"
}

#display warning message if original file will be removed
warning_message(){
 echo "Warning"
}

init