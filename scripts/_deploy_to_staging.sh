#!/bin/sh

set -e

[ -z "${GITHUB_PAT}" ] && exit 0
[ "${TRAVIS_BRANCH}" != "master" ] && exit 0
[ "${TRAVIS_PULL_REQUEST}" = false ] && exit 0

git config --global user.email "steem.guides@gmail.com"
git config --global user.name "Steem Guides Team"

git clone -b gh-pages https://${GITHUB_PAT}@github.com/${TRAVIS_REPO_SLUG}-staging.git book-output-staging
cd book-output-staging
cp -r ../_book/* ./
git add --all *
git commit -m"Update the book" || true
git push -q origin gh-pages