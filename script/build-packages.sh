#!/bin/bash

REPO_NAME='ahayworth'
REPO_LOC='/repo'

function buildpkg() {
  aur sync \
    --upgrades \
    --chroot \
    --bind-rw $REPO_LOC \
    --temp \
    --remove \
    --noview \
    --noconfirm \
    --database $REPO_NAME \
    --root $REPO_LOC \
    "$1"
}

function listrepo() {
  aur repo -d $REPO_NAME -r $REPO_LOC -l | egrep -v '^\-'
}

function fix_symlinks() {
  for e in db files; do
    rm -f $REPO_LOC/$REPO_NAME.$e $REPO_LOC/$REPO_NAME.$e.tar.old
    ln -sf $REPO_LOC/$REPO_NAME.$e.tar $REPO_LOC/$REPO_NAME.$e
  done
}

function gcloud_login() {
  echo $GCLOUD_CREDENTIALS | base64 -d > /tmp/gcloud.json
  gcloud auth activate-service-account --key-file /tmp/gcloud.json
}

function gcloud_sync() {
  gsutil -m rsync -d -r "$1" "$2"
}

gcloud_login

gcloud_sync gs://archlinux-packages $REPO_LOC
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
    repo-remove $REPO_LOC/$REPO_NAME.db.tar $pkg
    rm -f $REPO_LOC/$pkg*.pkg.tar.*
  fi
done < <(listrepo)

fix_symlinks
gcloud_sync $REPO_LOC gs://archlinux-packages

echo "Done! Current packages:"
listrepo
