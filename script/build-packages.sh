#!/bin/bash

echo $GCLOUD_CREDENTIALS | base64 -d > /tmp/gcloud.json
gcloud auth activate-service-account --key-file /tmp/gcloud.json

gsutil cp gs://archlinux-packages/ahayworth.db /tmp/
aur repo -d ahayworth -r /tmp -l \
  | aur vercmp \
  | xargs aur sync --noconfirm

pkglist=$(aur repo -d ahayworth -r /tmp -l)
while read pkg; do
  if ! echo $pkglist | grep -q "$pkg"; then
    aur sync --noconfirm $pkg
  fi
done < packages

ls -al
ls -al /tmp
