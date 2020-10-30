#!/usr/bin/env bash

TMPDIR="${PWD}"

git config --global credential.helper 'cache --timeout=3000'

[[ ! -d test/repos ]] && mkdir -p test/repos
cd test/repos

[[ ! -d forkfile-test1 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test1.git
cd forkfile-test1
date > TIMESTAMP
git add .
git commit -am "-- TIMESTAMP --"
git push
cd ..

[[ ! -d forkfile-test2 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test2.git
cd forkfile-test2
date > TIMESTAMP
git add .
git commit -am "-- TIMESTAMP --"
git push
cd ..

[[ ! -d forkfile-test3 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test3.git
cd forkfile-test3
date > TIMESTAMP
git add .
git commit -am "-- TIMESTAMP --"
git push
cd ..

cd "${TMPDIR}"

echo ""
echo ""
echo "====[ FORK.SH ]===="
