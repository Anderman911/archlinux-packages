#!/bin/bash

REPO_NAME='ahayworth'
REPO_LOC='/repo'
CHROOT_BASE='/var/lib/archbuild/aur-x86_64'
CHROOT="${CHROOT_BASE}/root"
CHROOT_PACMAN_CONF="/usr/share/devtools/pacman-aur.conf"

function makechroot() {
  sudo mkdir -p $CHROOT_BASE
  sudo mkarchroot -C $CHROOT_PACMAN_CONF $CHROOT base-devel git

  while read key; do
    sudo arch-nspawn $CHROOT pacman-key --recv-keys $key
  done < /home/builder/archlinux-packages/keys
}

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

function b2_sync() {
  b2 authorize-account
  b2 sync --delete --replaceNewer "$1" "$2"
}

b2_sync b2://ahayworth-archlinux-packages $REPO_LOC
fix_symlinks
makechroot
sudo sed -i -e 's/makechrootpkg_args=(\-c \-n \-C)/makechrootpkg_args=(-c)/g' /usr/sbin/archbuild

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
done < /home/builder/archlinux-packages/packages

while read pkg ver; do
  if ! grep -q "$pkg" /home/builder/archlinux-packages/packages; then
    echo "Removing $pkg..."
    repo-remove $REPO_LOC/$REPO_NAME.db.tar $pkg
    rm -f $REPO_LOC/$pkg*.pkg.tar.*
  fi
done < <(listrepo)

fix_symlinks
b2_sync $REPO_LOC b2://ahayworth-archlinux-packages

echo "Done! Current packages:"
listrepo
