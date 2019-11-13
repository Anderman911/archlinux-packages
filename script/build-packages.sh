#!/bin/bash

function listrepo() {
  aur repo -d ahayworth -r /tmp -l
}

echo $GCLOUD_CREDENTIALS | base64 -d > /tmp/gcloud.json
gcloud auth activate-service-account --key-file /tmp/gcloud.json
gsutil -m rsync -d -r gs://archlinux-packages /repo

listrepo

listrepo | aur vercmp | xargs aur sync --noconfirm
while read pkg; do
  if ! listrepo | grep -q "$pkg"; then
    aur sync --noconfirm $pkg
  fi
done < packages

ls -al
ls -al /tmp

listrepo
