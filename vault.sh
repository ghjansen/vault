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
DELETEORIGINAL=false
DELETEENCRYPTEDCOPY=false

#colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#arguments
OPERATION="$1"
FILE="$2"
TARFILENAME="$FILE.tar"

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
  if [ -z ${VAULTCONF+x} ]; then
    . vault.conf
  else
    . $VAULTCONF
  fi
}

#validate file
validate(){
  echo "Validating file '$FILE'"
  if [ ! -e "$PWD/$FILE" ]; then
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

#decrypt file
decrypt(){
  GPGPARAMS=""
  #disable key cache
  if [[ $SYMKEYCACHE == "false" ]]; then
    GPGPARAMS="--no-symkey-cache "
  fi
  GPGPARAMS="$GPGPARAMS--output $PWD/${FILE%.*} $PWD/$FILE"
  #decrypt file
  gpg -d $GPGPARAMS
  #check if file was decrypted
  if [ -e "$PWD/${FILE%.*}" ]; then
    echo "Decrypted file '$FILE'"
  else
    printf "${RED}ERROR: Failed to decrypt file '${FILE%.*}'.${NC}\n"
    exit 1
  fi
}

#decompress decrypted file
untar(){
  #check if the file is compressed
  TARPARAMS=""
  DECRYPTEDTYPE=$(file $PWD/${FILE%.*})
  if [[ $DECRYPTEDTYPE == *"gzip compressed data"* ]]; then
    TARPARAMS="-xzf"
    FILEXT=".tar.gz"
  elif [[ $DECRYPTEDTYPE == *"POSIX tar archive"* ]]; then
    TARPARAMS="-xf"
    FILEXT=".tar"
  else
    rm -rf $PWD/${FILE%.*}
    printf "${RED}ERROR: Decripted file '${FILE%.*}' is not supported and it was deleted.${NC}\n"
    exit 1
  fi
  #extract
  tar $TARPARAMS $PWD/${FILE%.*}
  if [ ! -e "$PWD/${FILE%$FILEXT}" ]; then
    printf "${RED}ERROR: Failed to extract '${FILE%.*}'.${NC}\n"
    exit 1
  fi
  echo "Extracted file '${FILE%$FILEXT.gpg}'"
  #delete tarball
  rm -rf $PWD/${FILE%.*}
  if [ -e "$PWD/${FILE%.*}" ]; then
    printf "${RED}ERROR: Failed to delete '${FILE%.*}'. Please try to delete it manually.${NC}\n"
    exit 1
  else
    echo "Deleted file '${FILE%.*}'"
  fi
}

#delete encrypted file after decryption
delete_encrypted_copy(){
  if [[ $DELETEENCRYPTEDCOPY == "true" ]]; then
    rm -rf $PWD/$FILE
    if [ -e "$PWD/$FILE" ]; then
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
  warning_message
  compress
  encrypt
  delete_original
  printf "${GREEN}Vault closed.${NC}\n"
}

#display warning message if original file will be removed
warning_message(){
  if [[ $DELETEORIGINAL == "true" ]]; then
    printf "${YELLOW}#####################################${NC}\n"
    printf "${YELLOW}#             WARNING!              #${NC}\n"
    printf "${YELLOW}#####################################${NC}\n"
    printf "${YELLOW}The file '$FILE' will be PERMANENTLY DELETED after the creation of its encypted copy.${NC}\n"
    printf "${YELLOW}Make sure to SAVE THE PASSPHRASE you are about to use for encryption.${NC}\n"
    printf "${YELLOW}THE PASSPHRASE you are about to use will be the ONLY WAY TO RECOVER '$FILE'.${NC}\n"
    printf "${YELLOW}This operation is NOT REVERSIBLE and LOOSING YOUR PASSPHRASE means LOOSING '$FILE'!${NC}\n"
    confirmation
  fi
}

#ask for user confirmation
confirmation(){
  printf "Do you wish to continue? (yes/no): "
  read CONFIRMATION
  case $CONFIRMATION in
  yes)
    ;;
  no)
    printf "${RED}Vault operation aborted.${NC}\n"
    exit 1
    ;;
  *)
    echo "Please type 'yes' or 'no'."
    confirmation
    ;;
  esac
}

#compress file to be encrypted
compress(){
  TARPARAMS="-cf"
  if [[ $COMPRESS == "true" ]]; then
    TARPARAMS="-czf"
    TARFILENAME="$FILE.tar.gz"
  fi
  tar $TARPARAMS $TARFILENAME $FILE
  #check if file was compressed
  if [ -e "$PWD/$TARFILENAME" ]; then
    echo "Compressed file '$FILE'"
  else
    printf "${RED}ERROR: Failed to compress file '$FILE'.${NC}\n"
    exit 1
  fi
}

#encrypt file
encrypt(){
  GPGPARAMS=""
  #disable key cache
  if [[ $SYMKEYCACHE == "false" ]]; then
    GPGPARAMS="--no-symkey-cache "
  fi
  GPGPARAMS="$GPGPARAMS--personal-cipher-preferences $CIPHER $PWD/$TARFILENAME"
  #encrypt file
  gpg -c $GPGPARAMS
  #check if file was decrypted
  if [ -e "$PWD/$TARFILENAME.gpg" ]; then
    echo "Encrypted file '$FILE'"
  else
    printf "${RED}ERROR: Failed to encrypt file '$FILE'.${NC}\n"
    FAILED="true";
  fi
  #delete compressed file
  rm -rf "$PWD/$TARFILENAME"
  if [ -e "$PWD/$TARFILENAME" ]; then
    printf "${RED}ERROR: Failed to delete '$TARFILENAME'. Please try to delete it manually.${NC}\n"
    exit 1
  else
    echo "Deleted file '$TARFILENAME'"
  fi
  if [ -n "$FAILED" ]; then
    exit 1
  fi
}

#delete original file after encryption
delete_original(){
  if [[ $DELETEORIGINAL == "true" ]]; then
    rm -rf "$PWD/$FILE"
    if [ -e "$PWD/$FILE" ]; then
      printf "${RED}ERROR: Failed to delete '$FILE'. Please try to delete it manually.${NC}\n"
      exit 1
    else
      echo "Deleted original file '$FILE'"
    fi
  else
    echo "Keeping original file '$FILE'"
  fi
}

init