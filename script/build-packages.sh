#!/bin/bash

function buildpkg() {
  aur sync -u --noview --noconfirm -d ahayworth --root /repo "$1"
}

function listrepo() {
  aur repo -d ahayworth -r /repo -l
}

function fix_symlinks() {
  for e in db files; do
    rm -f /repo/ahayworth.$e /repo/ahayworth.$e.tar.old
    ln -sf /repo/ahayworth.$e.tar /repo/ahayworth.$e
  done
}

echo $GCLOUD_CREDENTIALS | base64 -d > /tmp/gcloud.json
gcloud auth activate-service-account --key-file /tmp/gcloud.json
gsutil -m rsync -d -r gs://archlinux-packages /repo

fix_symlinks

listrepo | aur vercmp -q > /tmp/needs_update
while read pkg; do
  echo "Updating $pkg..."
  buildpkg $pkg
done < /tmp/needs_update

while read pkg; do
  if ! listrepo | grep -q "$pkg"; then
    echo "Adding $pkg..."
    buildpkg $pkg
  fi
done < /home/builder/repo/packages

while read pkg ver; do
  if ! grep -q "$pkg" /home/builder/repo/packages; then
    echo "Removing $pkg..."
    repo-remove /repo/ahayworth.db.tar $pkg
  fi
done < <(listrepo)

fix_symlinks

gsutil -m rsync -d -r /repo gs://archlinux-packages

echo "Done! Current packages:"
listrepo
