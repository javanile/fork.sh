#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh

cd test/repos/forkfile-test1
date > CHANGES.txt
git add .
git commit -am "Changes"
git push
cd ../../..

bash ./fork.sh --hard --update https://gitlab.com/javanile/fixtures/forkfile-test3.git

cd test/repos/forkfile-test3
#git pull

test diff CHANGES.txt ../forkfile-test1/CHANGES.txt
