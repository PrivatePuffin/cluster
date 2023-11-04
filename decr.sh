#!/bin/bash

export SOPS_AGE_KEY_FILE="age.key"
FILES=('patches/custom/controlplane.json' 'patches/custom/worker.json' 'config/talosconfig')

while IFS=  read -r -d $'\0'; do
    FILES+=("$REPLY")
done < <(find . -name "*.yaml" -type f -print0)

while IFS=  read -r -d $'\0'; do
    FILES+=("$REPLY")
done < <(find . -name "*.secret" -type f -print0)


if test -f "ENCRYPTED"; then
  for value in "${FILES[@]}"
  do
    echo "$value"
    sops -d -i "$value" || echo "skipping..."
  done
  rm -f ENCRYPTED
else
  echo "ERROR DATA ALREADY DECRYPTED"
fi
