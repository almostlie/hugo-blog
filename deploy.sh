#!/bin/bash

rm -rf ./public/*

rm -rf ./public/.git

hugo -t even

cd public

git init

git add ./

git commit -m "first commit"

git remote add origin https://github.com/newcome/newcome.github.com

git push -uf origin master

rm -rf ./*

rm -rf ./.git