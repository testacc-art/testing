#!/bin/bash

echo "pwd: $PWD"
echo "env:"
env
echo ""
echo "git status"
git status

echo "ok" > foo/b.txt
echo "ok" > bar/a.txt
echo "ok" > bar/b.txt
