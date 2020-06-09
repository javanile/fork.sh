#!/usr/bin/env bash

git config credential.helper 'cache --timeout=3000'

cd test/fixtures

cd forkfile
git add .
git commit -am "Forkfile"
git push
cd ..

cd php-package
git add .
git commit -am "Forkfile"
git push
cd ..

cd mysql-import
echo ""
echo ""
echo "====[ FORK.SH ]===="
../../../fork.sh
cd ..
