# gravity-assist

A command line tool to help you initialize a new git-based project or fork with:

- GitHub repository
- Enforcement of conventional commit comments (commitlint and husky)
- Changelog generation (git-cliff)
- dotenvx secret management via .env files
- Automatic version bumping
- Automatic npm and github releases (release-it)
- Readme file scaffolding

## Example Output

You can see an example of the repository config that gravity-assist produces at : [https://github.com/cunneen/gravity-assist-example-output](https://github.com/cunneen/gravity-assist-example-output).

## Usage

This repository itself was created with `gravity-assist`.

Run `npx gravity-assist` for an interactive session.

## Requirements

The following tools must be installed on your machine:

- [node](https://nodejs.org/) - at least v18
- [git](https://git-scm.com/)
- [nvm](https://github.com/nvm-sh/nvm)
- [npm](https://www.npmjs.com/)
- [gh](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/)

## Example Transcript

```console
$ nvm use v18
Now using node v18.20.6 (npm v10.8.2)
$ ./gravity-assist/gravity-assist.sh

=== CHECKING PREREQUISITES ===
checking for git
checking for nvm
checking for npm
checking for jq
checking for gh
checking for curl
checking for realpath
checking for dirname
checking for node
comparing NODE_VERSION=18.20 with NODE_MIN_VERSION=18
=== CONFIGURATION ===
Please answer a few questions to configure this script, or Ctrl-C to exit.
--
Fork an existing repo, or create a completely new one? (new|existing) [existing]: new
new repository selected.
--
Should the new GitHub repo be public or private? (public|private) [public]: 
public selected.
--
NOTE: you can see a full list of license identifiers here: 

    https://spdx.org/licenses/ 


Enter the IDENTIFIER of the license you want to use (e.g. MIT) [MIT]: 
MIT selected.
--
Enter a short description of your repository, to appear on GitHub and npm.
Max 350 chars.
E.g. A node module for reticulating splines [A module which... (enter your description here)]: An example repository created by gravity-assist
'An example repository created by gravity-assist' selected.
--
A .nvmrc file will be created in the new folder, specifying the minimum node version.
If you're not using node js, just accept the default value.
Minimum node version [20]: 
Minimum node version will be set to 20.
--
A new folder will be created in your current working directory /Users/mikecunneen/Development.
What is the name for the NEW folder (and project)? [gravity-assist]: gravity-assist-example-output
gravity-assist-example-output selected as new project/folder name.
---- Checking gh auth status ... ----
github.com
  ✓ Logged in to github.com account cunneen (keyring)
  - Active account: true
  - Git operations protocol: https
  - Token: gho_************************************
  - Token scopes: 'delete_repo', 'gist', 'read:org', 'repo', 'workflow'
---- Setting up gravity-assist-example-output ... ----
---- Setting node version to 20 ... ----
Now using node v20.12.2 (npm v10.5.0)
---- Initialising git ... ----
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint: 
hint: 	git config --global init.defaultBranch <name>
hint: 
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 
hint: 	git branch -m <name>
Initialized empty Git repository in /Users/mikecunneen/Development/gravity-assist-example-output/.git/
setting up a README.md file
Reinitialized existing Git repository in /Users/mikecunneen/Development/gravity-assist-example-output/.git/
[main (root-commit) 73560f0] chore: Add README.md
 1 file changed, 258 insertions(+)
 create mode 100644 README.md
---- Adding your chosen license ... ----
-- NOTE: you can see the full list of licenses at:
-- https://spdx.org/licenses/
Successfully wrote the MIT license
Most information *should* have been updated with your details but it is best to double check to make sure it is all correct.
---- Initialising npm ... ----
---- Initialising GitHub repo ----
✓ Created repository cunneen/gravity-assist-example-output on GitHub
  https://github.com/cunneen/gravity-assist-example-output
✓ Added remote https://github.com/cunneen/gravity-assist-example-output.git
---- setting up @dotenvx/dotenvx ----

added 30 packages, and audited 31 packages in 5s

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
✔ ignored .env.keys (.gitignore)
✔ ignored !/.env (.gitignore)
✔ encrypted (.env)
✔ key added to .env.keys (DOTENV_PRIVATE_KEY)
⮕  next run [DOTENV_PRIVATE_KEY='865d6fe.............................'  dotenvx run -- yourcommand] to test decryption locally
---- setting up mocha and a test of dotenvx ----

added 105 packages, and audited 136 packages in 4s

40 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
---- testing dotenvx ----

> gravity-assist-example-output@0.0.1 test
> dotenvx run -- ./node_modules/.bin/mocha

[dotenvx@1.38.4] injecting env (2) from .env


  dotenvx
    ✔ should decrypt process.env.HELLO value


  1 passing (1ms)

---- setting up commitlint ----

added 86 packages, and audited 222 packages in 12s

58 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
---- setting up husky ----

added 1 package, and audited 223 packages in 2s

59 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
---- testing a commit ----
---- commit linting looks good ----
---- creating empty CHANGELOG.md ... ----
---- Setting up git-cliff ----

added 12 packages, and audited 235 packages in 2s

67 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
 INFO  git_cliff > Saving the configuration file to "cliff.toml"
---- Setting up release-it ----
npm WARN deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm WARN deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported

added 241 packages, and audited 476 packages in 14s

143 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
---- creating .release-it.json ... ----
---- Done! ----

Now try the following:
    cd gravity-assist-example-output


  Stage the new files for our first commit:
    git add .


  Create the first commit WITHOUT using conventional commit comments -- it should fail! :
    git commit -m 'first commit'


  Create the first commit USING conventional commit comments -- it should work! :
    git commit -m 'chore: first commit'


  Push your commit to github:
    git push --set-upstream origin main


  Create your first release interactively:
    npm run release
Script completed successfully
```

```console
$ cd gravity-assist-example-output
$ git add .

```

### Conventional Commits enforced

```console
$ git commit -m 'first commit'

> gravity-assist-example-output@0.0.1 test
> dotenvx run -- ./node_modules/.bin/mocha

[dotenvx@1.38.4] injecting env (2) from .env


  dotenvx
    ✔ should decrypt process.env.HELLO value


  1 passing (2ms)


> gravity-assist-example-output@0.0.1 commitlint
> commitlint --edit .git/COMMIT_EDITMSG

⧗   input: first commit
✖   subject may not be empty [subject-empty]
✖   type may not be empty [type-empty]

✖   found 2 problems, 0 warnings
ⓘ   Get help: https://github.com/conventional-changelog/commitlint/#what-is-commitlint

husky - commit-msg script failed (code 1)
$ git commit -m 'chore: first commit'

> gravity-assist-example-output@0.0.1 test
> dotenvx run -- ./node_modules/.bin/mocha

[dotenvx@1.38.4] injecting env (2) from .env


  dotenvx
    ✔ should decrypt process.env.HELLO value


  1 passing (1ms)


> gravity-assist-example-output@0.0.1 commitlint
> commitlint --edit .git/COMMIT_EDITMSG

[main 7c39ae5] chore: first commit
 13 files changed, 6256 insertions(+)
 create mode 100644 .commitlintrc.cjs
 create mode 100644 .env
 create mode 100644 .gitignore
 create mode 100644 .husky/commit-msg
 create mode 100644 .husky/pre-commit
 create mode 100644 .nvmrc
 create mode 100644 .release-it.json
 create mode 100644 CHANGELOG.md
 create mode 100644 LICENSE
 create mode 100644 cliff.toml
 create mode 100644 package-lock.json
 create mode 100644 package.json
 create mode 100644 test/dotenvx.test.js
$ git push --set-upstream origin main
Enumerating objects: 20, done.
Counting objects: 100% (20/20), done.
Delta compression using up to 8 threads
Compressing objects: 100% (14/14), done.
Writing objects: 100% (20/20), 57.87 KiB | 9.64 MiB/s, done.
Total 20 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/cunneen/gravity-assist-example-output.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

### Creating a new release

```console
$ npm run release
> gravity-assist-example-output@0.0.1 release
> dotenvx run release-it -- -i -u

[dotenvx@1.38.4] injecting env (2) from .env
WARNING Environment variable "GITHUB_TOKEN" is required for automated GitHub Releases.
WARNING Falling back to web-based GitHub Release.

🚀 Let's release gravity-assist-example-output (currently at 0.0.1)


Changelog:
* chore: first commit (7c39ae5)
* chore: Add README.md (73560f0)

✔ Select increment (next version): patch (0.0.2)
✔ npm run release-changelog 0.0.2

Changeset:
 M CHANGELOG.md
 M package-lock.json
 M package.json

✔ Commit (chore: release 0.0.2)? Yes
✔ Tag (0.0.2)? Yes
✔ Push? Yes
✔ Create a release on GitHub (Release 0.0.2)? Yes
🔗 https://github.com/cunneen/gravity-assist-example-output/releases/tag/0.0.2
🏁 Done (in 17s.)
```
