#!/usr/bin/env sh

encrypted_files () {
  FILES=()
  while IFS=  read -r -d $'\0'; do
      FILES+=("$REPLY")
  done < <(find . -name "*.yaml" -type f -print0)

  while IFS=  read -r -d $'\0'; do
      FILES+=("$REPLY")
  done < <(find . -name "*.secret" -type f -print0)
}
export encrypted_files

decrypt () {
  echo "Trying to decrypt data..."
  export SOPS_AGE_KEY_FILE="age.agekey"

  encrypted_files


  for value in "${FILES[@]}"
  do
    sops -d -i "$value" >/dev/null 2>&1 || echo ""
  done
  rm -f ENCRYPTED

}
export decrypt

encrypt () {
  export SOPS_AGE_KEY_FILE="age.agekey"

  encrypted_files

  for value in "${FILES[@]}"
  do
    if grep -Fxq "sops:" $value; then
      echo "$value already encrypted, skipping..."
    else
      sops --encrypt -i "$value" >/dev/null 2>&1 || echo ""
    fi
  done
}
export encrypt

if [ "$1" = "decrypt" ] ; then
  decrypt
elif [ "$1" = "encrypt" ] ; then
  encrypt
fi
