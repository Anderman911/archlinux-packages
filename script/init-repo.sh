#!/bin/bash

repo-add /repo/ahayworth.db.tar
echo $GCLOUD_CREDENTIALS | base64 -d > /tmp/gcloud.json
gcloud auth activate-service-account --key-file /tmp/gcloud.json
gsutil -m rsync -d -r /repo gs://archlinux-packages
