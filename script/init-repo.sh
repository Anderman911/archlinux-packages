#!/bin/bash

repo-add /repo/ahayworth.db.tar
b2 sync --delete --replaceNewer /repo b2://ahayworth-archlinux-packages/
