#!/bin/bash

cd public

git init

git add ./

git commit -m "first commit"

git remote add origin https://github.com/newcome/newcome.github.com

git push -uf origin master

mv .gitignore ../.gitignorebak

rm -rf ./*

rm -rf ./.git

mv ../.gitignorebak .gitignore

