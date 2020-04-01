#!/usr/bin/env bash
set -e

git add .
git commit -am "push"
git push

docker build -t javanile/fork.sh .
docker push javanile/fork.sh:latest
