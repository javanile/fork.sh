#!/usr/bin/env bash
set -e

TMPDIR="${PWD}"

git config --global credential.helper 'cache --timeout=3000'

[[ ! -d test/repos ]] && mkdir -p test/repos
cd test/repos

if [[ "$*" == *1* ]]; then
    [[ ! -d forkfile-test1 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test1.git
    cd forkfile-test1
    git pull
    date > TIMESTAMP
    git add .
    git commit -am "-- TIMESTAMP --"
    git push
    cd ..
fi

if [[ "$*" == *2* ]]; then
    [[ ! -d forkfile-test2 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test2.git
    cd forkfile-test2
    git pull
    date > TIMESTAMP
    git add .
    git commit -am "-- TIMESTAMP --"
    git push
    cd ..
fi

if [[ "$*" == *3* ]]; then
    [[ ! -d forkfile-test3 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test3.git
    cd forkfile-test3
    git pull
    date > TIMESTAMP
    git add .
    git commit -am "-- TIMESTAMP --"
    git push
    cd ..
fi

if [[ "$*" == *4* ]]; then
    [[ ! -d forkfile-test4 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test4.git
    cd forkfile-test4
    git pull
    date > TIMESTAMP
    git add .
    git commit -am "-- TIMESTAMP --"
    git push
    cd ..
fi

cd "${TMPDIR}"

echo ""
echo ""
echo "====[ FORK.SH ]===="

test() {
    echo ""
    echo "====[ TESTING ]===="
    echo ">>> ${@}"
    ${@}
    echo "OK."
}
