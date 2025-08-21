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
PREREQUISITES="git nvm npm jq gh curl realpath dirname node"
# Date as YYYYMMDD
DATE=$(date +%Y%m%d)
# node minimum version to run this script
NODE_MIN_VERSION=18

# ==== CONFIGURATION DEFAULT VALUES FOR PROMPTS - change as needed ====
DEFAULT_NEW_OR_EXISTING=existing
DEFAULT_NEW_FOLDER_NAME=gravity-assist
DEFAULT_NEW_REPO_PUBLIC_OR_PRIVATE=public
DEFAULT_EXISTING_REPO_TO_FORK=https://github.com/cunneen/gravity-assist.git
DEFAULT_LICENSE=MIT
DEFAULT_DESCRIPTION="A module which... (enter your description here)"
# node minimum version for .nvmrc
DEFAULT_NVM_NODE_MIN_VERSION=20


# ===== Error handling =======
# set -e: exit on error
set -e

# invoke the catch() function whenever an error occurs
trap 'catch $? $LINENO' EXIT

# catch() function just prints an error message (before exit)
catch() {
  if [ "$1" != "0" ]; then
    # error handling goes here
    echo "    (Exiting due to return code $1 on line $2)" >&2
  else
    echo "Script completed successfully"
  fi
}

# escape_regex() function escapes special characters
escape_regex() {                                                                                                                                                                                                               system
    local input="$1"
    echo "$input" | sed -E -e 's/[\/]/\\\//g; s/[.+*^$[]/\\&/g; '                   
}

# ==== TEST FOR PREREQUISITES ====
echo "=== CHECKING PREREQUISITES ==="
for cmd in ${PREREQUISITES}
do
  echo "checking for ${cmd}"
  if [ "${cmd}" == "nvm" ]; then
    # load nvm
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

  else
    command -v ${cmd} >/dev/null 2>&1 || {
      echo -e "===== ERROR - MISSING PREREQUISITE =====\n" >&2
      echo -e "PATH:\n$(echo $PATH | tr ':' '\n' | sed 's/^/  /')\n" >&2
      echo -e "-----------------------------------------\n" >&2
      echo -e "ERROR: I require ${cmd} but it's not in your PATH. \n\n" >&2
      exit 1
    }
  fi
done

# check node version
NODE_VERSION=$(node -v  | cut -d '.' -f 1,2 | cut -d 'v' -f 2)
echo "comparing NODE_VERSION=${NODE_VERSION} with NODE_MIN_VERSION=${NODE_MIN_VERSION}"
if [ ${NODE_VERSION} \< ${NODE_MIN_VERSION} ]; then
  echo -e "\n\n===== ERROR - NODE VERSION =====\n\n" >&2
  echo "ERROR: This script requires node >= ${NODE_MIN_VERSION}; you are running node ${NODE_VERSION}"
  exit 1
fi

# ---- Configuration - prompt user for values, falling back to defaults ---
echo "=== CONFIGURATION ==="
echo "Please answer a few questions to configure this script, or Ctrl-C to exit."
echo "--"
while [ "${NEW_OR_EXISTING}" != "new" ] && [ "${NEW_OR_EXISTING}" != "existing" ]; do
  read -p "Fork an existing repo, or create a completely new one? (new|existing) [$DEFAULT_NEW_OR_EXISTING]: " NEW_OR_EXISTING
  # fall back to defaults where no values are provided
  NEW_OR_EXISTING=${NEW_OR_EXISTING:-$DEFAULT_NEW_OR_EXISTING}
  if [ "${NEW_OR_EXISTING}" != "new" ] && [ "${NEW_OR_EXISTING}" != "existing" ]; then
    echo "Please enter 'new' to create a new repo, or 'existing' to fork an existing one."
  fi
done
echo "${NEW_OR_EXISTING} repository selected."

if [ "${NEW_OR_EXISTING}" == "existing" ]; then
  echo "--"
  echo "This script currently only works with GitHub repositories."
  while [ "${EXISTING_REPO_TO_FORK}" == "" ] || [[ ! "${EXISTING_REPO_TO_FORK}" =~ ^https://github.com/ ]] ; do
    read -p "Provide the full URL to the repo you want to fork (e.g. 'https://github.com/cunneen/gravity-assist.git')[$DEFAULT_EXISTING_REPO_TO_FORK]: " EXISTING_REPO_TO_FORK
    # fall back to defaults where no values are provided
    EXISTING_REPO_TO_FORK=${EXISTING_REPO_TO_FORK:-$DEFAULT_EXISTING_REPO_TO_FORK}
    if [[ ! "${EXISTING_REPO_TO_FORK}" =~ ^https://github.com/ ]]; then
      echo "Please provide a GitHub URL."
    fi
  done
  echo "${EXISTING_REPO_TO_FORK} selected."
elif [ "${NEW_OR_EXISTING}" == "new" ]; then
  echo "--"
  while [ "${NEW_REPO_PUBLIC_OR_PRIVATE}" != "public" ] && [ "${NEW_REPO_PUBLIC_OR_PRIVATE}" != "private" ]; do
    read -p "Should the new GitHub repo be public or private? (public|private) [$DEFAULT_NEW_REPO_PUBLIC_OR_PRIVATE]: " NEW_REPO_PUBLIC_OR_PRIVATE
    # fall back to defaults where no values are provided
    NEW_REPO_PUBLIC_OR_PRIVATE=${NEW_REPO_PUBLIC_OR_PRIVATE:-$DEFAULT_NEW_REPO_PUBLIC_OR_PRIVATE}
    if [ "${NEW_REPO_PUBLIC_OR_PRIVATE}" != "public" ] && [ "${NEW_REPO_PUBLIC_OR_PRIVATE}" != "private" ]; then
      echo "Please enter 'public' or 'private'."
    fi
  done
  echo "${NEW_REPO_PUBLIC_OR_PRIVATE} selected."

  echo "--"
  while [ "${LICENSE}" == "" ] || [[ ! "${LICENSE}" =~ ^(.{3,})$ ]] ; do
    echo -e "NOTE: you can see a full list of license identifiers here: \n\n    https://spdx.org/licenses/ \n\n"
    read -p "Enter the IDENTIFIER of the license you want to use (e.g. MIT) [$DEFAULT_LICENSE]: " LICENSE
    # fall back to defaults where no values are provided
    LICENSE=${LICENSE:-$DEFAULT_LICENSE}
    if [[ ! "${LICENSE}" =~ ^(.{3,})$ ]] ; then
      echo "Invalid license identifier"
    fi
  done
  echo "${LICENSE} selected."

  echo "--"
  while [ "${DESCRIPTION}" == "" ] || [ ${#DESCRIPTION} -lt 4 ] || [ ${#DESCRIPTION} -gt 350 ]  ; do
    echo "Enter a short description of your repository, to appear on GitHub and npm."
    echo "Max 350 chars."
    read -p "E.g. A node module for reticulating splines [$DEFAULT_DESCRIPTION]: " DESCRIPTION
    # fall back to defaults where no values are provided
    DESCRIPTION=${DESCRIPTION:-$DEFAULT_DESCRIPTION}
    if [ ${#DESCRIPTION} -lt 4 ] ; then
      echo "Description is too short."
    elif [ ${#DESCRIPTION} -gt 350 ] ; then
      echo "Description has a maximum length of 350 characters."
    fi
  done
  echo "'${DESCRIPTION}' selected."
  DESCRIPTION_ESCAPED=$(escape_regex "${DESCRIPTION}")

  echo "--"
  echo "A .nvmrc file will be created in the new folder, specifying the minimum node version."
  echo "If you're not using node js, just accept the default value."
  read -p "Minimum node version [$DEFAULT_NVM_NODE_MIN_VERSION]: " NVM_NODE_MIN_VERSION
  NVM_NODE_MIN_VERSION=${NVM_NODE_MIN_VERSION:-$DEFAULT_NVM_NODE_MIN_VERSION}
  echo "Minimum node version will be set to ${NVM_NODE_MIN_VERSION}."

fi

echo "--"
echo "A new folder will be created in your current working directory $(PWD)."
read -p "What is the name for the NEW folder (and project)? [$DEFAULT_NEW_FOLDER_NAME]: " NEW_FOLDER_NAME
NEW_FOLDER_NAME=${NEW_FOLDER_NAME:-$DEFAULT_NEW_FOLDER_NAME}
NEW_FOLDER_NAME_ESCAPED=$(escape_regex "${NEW_FOLDER_NAME}")

if [ "${NEW_FOLDER_NAME}" != "${NEW_FOLDER_NAME_ESCAPED}" ]; then
  echo "Folder name contains special characters. Exiting."
  echo "FOLDER_NAME: ${NEW_FOLDER_NAME}"
  echo "FOLDER_NAME_ESCAPED: ${NEW_FOLDER_NAME_ESCAPED}"
  exit 1
fi

echo "${NEW_FOLDER_NAME} selected as new project/folder name."


# ==== END OF CONFIGURATION ====

# ===== MAIN SCRIPT =======

echo "---- Checking gh auth status ... ----"
(gh auth status || gh auth login)

if [ "${NEW_OR_EXISTING}" == "new" ]; then
  echo "---- Setting up ${NEW_FOLDER_NAME} ... ----"
  mkdir -p "${NEW_FOLDER_NAME}" && command cd "${NEW_FOLDER_NAME}"
  echo "---- Setting node version to ${NVM_NODE_MIN_VERSION} ... ----"
  echo ${NVM_NODE_MIN_VERSION} > .nvmrc && nvm use ${NVM_NODE_MIN_VERSION}
  echo "---- Initialising git ... ----"
  git init .
  USER_GIT_NAME=$(git config --global user.name)
  USER_GIT_EMAIL=$(git config --global user.email)
  GITHUB_USERNAME=$(gh api user -q ".login")
  TWITTER_USERNAME=$(gh api user -q ".twitter_username")
  if [ "${TWITTER_USERNAME}" == "null" ]; then
    TWITTER_USERNAME="twitter_handle"
  fi
  echo "setting up a README.md file"
  # download a template readme and find and replace placeholders
  curl -s -O https://raw.githubusercontent.com/othneildrew/Best-README-Template/refs/heads/main/BLANK_README.md
  sed -E -e "s/project_title/${NEW_FOLDER_NAME}/g" \
         -e "s/project_description/${DESCRIPTION_ESCAPED}/g" \
         -e "s/repo_name/${NEW_FOLDER_NAME}/g" \
         -e "s/project_license/${LICENSE}/g" \
         -e "s/github_username/${GITHUB_USERNAME}/g" \
         -e "s/twitter_handle/${TWITTER_USERNAME}/g" \
            BLANK_README.md > README.md
  rm BLANK_README.md
  git init
  git add README.md
  git branch -M main
  git commit -m "chore: Add README.md"
  echo "---- Adding your chosen license ... ----"
  echo "-- NOTE: you can see the full list of licenses at:"
  echo "-- https://spdx.org/licenses/"
  npx license@1.0.3 ${LICENSE}
  echo "---- Initialising npm ... ----"
  # get the name of the user
  echo '{}' > package.json
  npm pkg set "name"="${NEW_FOLDER_NAME}"
  npm pkg set "description"="${DESCRIPTION}"
  npm pkg set "version"="0.0.1"
  npm pkg set "type"="module"
  npm pkg set "main"="index.js"
  npm pkg set "author"="${USER_GIT_NAME}"
  npm pkg set "private"=false
  npm pkg set "publishConfig.access"="public"
  npm pkg set "license"="${LICENSE}"

  echo "---- Initialising GitHub repo ----"

  gh repo create ${NEW_FOLDER_NAME} \
    --${NEW_REPO_PUBLIC_OR_PRIVATE} \
    --add-readme \
    --remote origin \
    --description "${DESCRIPTION}" \
    --source .

# elseif forking a github repo
elif [ "${NEW_OR_EXISTING}" == "existing" ]; then
  echo "---- Forking ${EXISTING_REPO_TO_FORK} and cloning to ${NEW_FOLDER_NAME} ... ----"
  gh repo fork ${EXISTING_REPO_TO_FORK} --remote --clone ${NEW_FOLDER_NAME}
  command cd ${NEW_FOLDER_NAME}

  if [ -f "package.json" ]; then
    echo "---- Initialising npm ... ----"
    echo "Found existing package.json file. Backing up to package.json.bak"
    cp package.json package.json.bak
    echo "running npm init"
  else
    echo "---- Initialising npm ... ----"
    echo "No package.json file found. Creating one."
  fi
  npm init

fi

#### gitignore.io command line


# gitignore
echo >> .gitignore
curl -s https://www.toptal.com/developers/gitignore/api/visualstudiocode,node,osx >> .gitignore

#### dotenvx

echo "---- setting up @dotenvx/dotenvx ----";

npm add --save-dev @dotenvx/dotenvx

./node_modules/.bin/dotenvx ext gitignore --pattern .env.keys
./node_modules/.bin/dotenvx  ext gitignore --pattern '!/.env'

echo "HELLO=World" >> .env

# encrypt your .env file; this also creates a .env.keys file.
./node_modules/.bin/dotenvx encrypt

echo "---- setting up mocha and a test of dotenvx ----";
# update package.json to run mocha with dotenvx when "npm run test" is invoked
npm add --save-dev mocha chai 
npm pkg set scripts.test="dotenvx run -- ./node_modules/.bin/mocha"

# The first test script that mocha will run - just tests that dotenvx is working
mkdir -p test
cat <<-DOTENVXTEST > test/dotenvx.test.js
  import { assert } from "chai";

  describe("dotenvx", () => {
    it("should decrypt process.env.HELLO value", () => {
      assert.equal(process.env.HELLO, "World");
    });
  });

DOTENVXTEST

echo "---- testing dotenvx ----";

# lets give it a try
npm run test

#### commitlint
echo "---- setting up commitlint ----";

npm add --save-dev @commitlint/{cli,config-conventional}
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > .commitlintrc.cjs

#### husky
echo "---- setting up husky ----";

npm add --save-dev husky
./node_modules/.bin/husky init

if [ ! -f "${HOME}/.config/husky/init.sh" ]; then
  echo "creating ~/.config/husky/init.sh to load nvm"
  mkdir -p "${HOME}/.config/husky"
  touch "${HOME}/.config/husky/init.sh"
  echo "export NVM_DIR=\"\$([ -z \"\${XDG_CONFIG_HOME-}\" ] && printf %s \"\$HOME/.nvm\" || printf %s \"\$XDG_CONFIG_HOME/nvm\")\"" >> "${HOME}/.config/husky/init.sh"
  echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"" >> "${HOME}/.config/husky/init.sh"
fi

# Add commit message linting to commit-msg hook
npm pkg set scripts.commitlint="commitlint --edit"
echo "npm run commitlint \${1}" > .husky/commit-msg

# test a commit
COMMITWORKED=1;
echo "---- testing a commit ----";
git commit -m "test commit" --dry-run >/dev/null 2>&1 || COMMITWORKED=0;

if [ ${COMMITWORKED} -eq 1 ]; then
  # we have a problem, that shouldn't have worked.
  echo "++++++++++ ERROR ++++++++++\n\n" >&2
  echo "Our commit linting isn't working as expected \n\n" >&2
  exit 2
else
  echo "---- commit linting looks good ----"
fi

#### git-cliff for changelog generation / management

# find any existing changelog
num_changelogs=$(find . -iname 'changelog*' -maxdepth 1 | wc -l);
if [ $num_changelogs -eq 0 ]; then
  CHANGELOG="CHANGELOG.md"
  echo "---- creating empty ${CHANGELOG} ... ----"
  touch $CHANGELOG
elif [ $num_changelogs -eq 1 ]; then
  CHANGELOG="$(find . -iname 'changelog*' -maxdepth 1);"
  echo "---- found ${CHANGELOG} ... ----"
fi

echo "---- Setting up git-cliff ----"
npm add --save-dev git-cliff
./node_modules/.bin/git-cliff --init
npm pkg set "scripts.release-changelog"="git-cliff --unreleased --prepend ${CHANGELOG} --tag "

#### release-it for tagging and github releases
echo "---- Setting up release-it ----"
npm add --save-dev release-it
npm pkg set "scripts.release"="dotenvx run release-it -- -i -u"

# add the following to ".release-it.json"
echo "---- creating .release-it.json ... ----"
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
      "after:bump": "npm run release-changelog ${version}"
    }
  }
RELEASEIT

echo -e '---- Done! ----\n'
echo 'Now try the following:'
echo -e "    cd ${NEW_FOLDER_NAME}\n\n"
echo '  Stage the new files for our first commit:'
echo -e "    git add .\n\n"
echo "  Create the first commit WITHOUT using conventional commit comments -- it should fail! :"
echo -e "    git commit -m 'first commit'\n\n"
echo "  Create the first commit USING conventional commit comments -- it should work! :"
echo -e "    git commit -m 'chore: first commit'\n\n"
echo '  Push your commit to github:'
echo -e "    git push --set-upstream origin main\n\n"
echo '  Add your GitHub token for automatic releases:'
echo -e '    dotenvx set GITHUB_TOKEN $(gh auth token)\n\n'
echo '  Create your first release interactively:'
echo '    npm run release'

