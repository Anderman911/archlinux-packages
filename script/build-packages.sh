#!/bin/bash

function listrepo() {
  aur repo -d ahayworth -r /repo -l
}

echo $GCLOUD_CREDENTIALS | base64 -d > /tmp/gcloud.json
gcloud auth activate-service-account --key-file /tmp/gcloud.json
gsutil -m rsync -d -r gs://archlinux-packages /repo

listrepo
listrepo | aur vercmp -q | xargs aur sync --noconfirm -d ahayworth -r /repo
while read pkg; do
  if ! listrepo | grep -q "$pkg"; then
    aur sync --noconfirm -d ahayworth -r /repo $pkg
  fi
done < /home/builder/repo/packages

ls -al
ls -al /repo
ls -al /tmp

listrepo
