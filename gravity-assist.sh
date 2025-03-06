#!/bin/bash
# ===========================================================
# Script for configuring new git projects (or new forks) with:
# - enforcement of conventional commit comments (commitlint and husky)
# - changelog generation (git-cliff)
# - dotenvx secret management via .env files
# - automatic version bumping
# - automatic npm and github releases (release-it)
# ============================================================

# ==== CONSTANTS ====
# prerequisites must be in the path
PREREQUISITES="git nvm yarn gh curl realpath dirname"
# Date as YYYYMMDD
DATE=$(date +%Y%m%d)
# node minimum version for .nvmrc
NODE_MIN_VERSION=20

# ==== CONFIGURATION DEFAULT VALUES FOR PROMPTS - change as needed ====
DEFAULT_NEW_OR_EXISTING=existing
DEFAULT_NEW_FOLDER_NAME=gravity-assist
DEFAULT_EXISTING_REPO_TO_FORK=https://github.com/cunneen/gravity-assist.git

# ---- Configuration - prompt user for values, falling back to defaults ---
if [ ${INITIALISED:-0} -ne 1 ]; then
  # it's the first time
  echo "=== CONFIGURATION ==="

  read -p "Fork an existing repo, or create a completely new one? (new|existing)[$DEFAULT_NEW_OR_EXISTING]: " NEW_OR_EXISTING
  if [ "${NEW_OR_EXISTING}" == "existing" ]; then
    read -p "Provide the full URL to the repo you want to fork (e.g. "https://github.com/cunneen/gravity-assist.git")[$DEFAULT_EXISTING_REPO_TO_FORK]: " EXISTING_REPO_TO_FORK
  fi
  read -p "What is the name of the folder you want to create? [$DEFAULT_NEW_FOLDER_NAME]: " NEW_FOLDER_NAME

  # fall back to defaults where no values are provided
  NEW_OR_EXISTING=${NEW_OR_EXISTING:-$DEFAULT_NEW_OR_EXISTING}
  EXISTING_REPO_TO_FORK=${EXISTING_REPO_TO_FORK:-$DEFAULT_EXISTING_REPO_TO_FORK}
  NEW_FOLDER_NAME=${NEW_FOLDER_NAME:-$DEFAULT_NEW_FOLDER_NAME}
fi

INITIALISED=1 # set to 1 so that the script will not prompt again

# ==== END OF CONFIGURATION ====

# ===== Error handling =======
# set -e: exit on error
set -e

# invoke the catch() function whenever an error occurs
trap 'catch $? $LINENO' EXIT

# catch() function just prints an error message (before exit)
catch() {
  if [ "$1" != "0" ]; then
    # error handling goes here
    echo "Error $1 occurred on $2" >&2
  else
    echo "Script completed successfully"
  fi
}

######### test for prerequisites

# load nvm

for cmd in ${PREREQUISITES}
do
  echo "checking for ${cmd}"
  if [ "${cmd}" == "nvm" ]; then
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

  else
    command -v ${cmd} >/dev/null 2>&1 || {
      echo "!!!!!!!! ERROR !!!!!!!!\n\n" >&2
      echo "I require ${cmd} but it's not in your PATH. \n\n" >&2
      echo "PATH:${PATH}. \n\n" >&2
      exit 1
    }
  fi
done

# get the current dir
reldir=$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")
DIR="$(realpath "${PWD}/${reldir}")"

# ===== MAIN SCRIPT =======

if [ "${NEW_OR_EXISTING}" == "new" ]; then
  mkdir -p "${NEW_FOLDER_NAME}" && cd "${NEW_FOLDER_NAME}"

  echo ${NODE_MIN_VERSION} > .nvmrc && nvm use ${NODE_MIN_VERSION}

  git init .
  yarn init

  gh repo create ${NEW_FOLDER_NAME} --public

# elseif forking a github repo
elif [ "${NEW_OR_EXISTING}" == "existing" ]; then

  gh repo fork ${EXISTING_REPO_TO_FORK} --remote --clone ${NEW_FOLDER_NAME}
  command cd ${NEW_FOLDER_NAME}

fi

#### gitignore.io command line


# gitignore
echo >> .gitignore
curl -s https://www.toptal.com/developers/gitignore/api/visualstudiocode,node,osx >> .gitignore

#### dotenvx

echo "---- setting up @dotenvx/dotenvx ----";

yarn add -D @dotenvx/dotenvx

./node_modules/.bin/dotenvx ext gitignore --pattern .env.keys
./node_modules/.bin/dotenvx  ext gitignore --pattern '!/.env'

echo "HELLO=World" >> .env
echo "console.log('Hello ' + process.env.HELLO)" > sayhello.js

# encrypt your .env file; this also creates a .env.keys file.
./node_modules/.bin/dotenvx encrypt

# update package.json to have a 'testdotenvx' script
npm pkg set scripts.testdotenvx="dotenvx run -- node sayhello.js"

yarn run testdotenvx

#### commitlint
echo "---- setting up commitlint ----";

yarn add --dev @commitlint/{cli,config-conventional}
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > .commitlintrc.js

#### husky
echo "---- setting up husky ----";

yarn add --dev husky
yarn husky init

# Add commit message linting to commit-msg hook
npm pkg set scripts.commitlint="commitlint --edit"
echo "yarn commitlint \${1}" > .husky/commit-msg

# test a commit
COMMITWORKED=1;
echo "---- testing a commit; please ignore any errors ----";
git commit -m "test commit" --dry-run || COMMITWORKED=0;

if [ ${COMMITWORKED} -eq 1 ]; then
  # we have a problem, that shouldn't have worked.
  echo "!!!!!!!! ERROR !!!!!!!!\n\n" >&2
  echo "Our commit linting isn't working as expected \n\n" >&2
  exit 2
else
  echo "---- OK. ----"
fi

#### git-cliff for changelog generation / management

# find any existing changelog
num_changelogs=$(find . -iname 'changelog*' -maxdepth 1 | wc -l);
if [ $num_changelogs -eq 0 ]; then
  CHANGELOG="CHANGELOG.md"
  touch $CHANGELOG
elif [ $num_changelogs -eq 1 ]; then
  CHANGELOG="$(find . -iname 'changelog*' -maxdepth 1);"
fi

yarn add -D git-cliff
./node_modules/.bin/git-cliff --init
npm pkg set "scripts.release-changelog"="git-cliff --unreleased --prepend ${CHANGELOG} --tag "

#### release-it for tagging and github releases

yarn add -D release-it
npm pkg set "scripts.release"="dotenvx run release-it -- -i -u"

# add the following to ".release-it.json"

cat <<- "RELEASEIT" > .release-it.json
  {
    "$schema": "https://unpkg.com/release-it@17/schema/release-it.json",
    "git": {
      "commitMessage": "chore: release ${version}",
      "requireCleanWorkingDir": false
    },
    "github": {
      "release": true
    },
    "npm": {
      "publish": true
    },
    "hooks": {
      "after:bump": "yarn run release-changelog ${version}"
    }
  }
RELEASEIT