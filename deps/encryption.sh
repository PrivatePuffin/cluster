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
  rm -f ENCRYPTED
  echo "Trying to decrypt data..."
  export SOPS_AGE_KEY_FILE="age.agekey"

  encrypted_files


  for value in "${FILES[@]}"
  do
    sops -d -i "$value" >/dev/null 2>&1 || echo ""
  done

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
  touch ENCRYPTED
}
export encrypt

ensure () {
  if [ -f OVERRIDE ]; then
    echo "Encryption Check overridden"
  elif [ ! -f ENCRYPTED ]; then
      echo "ERROR NOT ENCRYPTED"
      exit 1
  fi
}
export encrypt

if [ "$1" = "decrypt" ] ; then
  decrypt
elif [ "$1" = "encrypt" ] ; then
  encrypt
elif [ "$1" = "ensure" ] ; then
  ensure
fi
