# git-worktree-relative


## Background

- I want to migrate very old project that didn't use git (like something from 2006's, where using git is not a common best practice - since git released in 2005)
  - The project structure is 'normal' web application, written in php
  - But it have various version, e.g.: production, production-bleeding (last stage in test, using production database), staging, test, and development; each on different server (and each of them should not be taken down or turned off for a few hour, not even the development version)
  - The team has managed to maintain all of those versions without git since 2006's (hats off to them), but now we decided to modernize our toolchain
  - Problem: how to merge those versions, each into 1 branch in git? My solution is to create worktree for each of them
  - Extra problem: git-worktree add CANNOT add from existing directory (https://stackoverflow.com/questions/59474143/add-existing-directory-as-branch-to-git-with-worktree) My solution is to add worktree with `--no-checkout` flag, then copy-and-replace content of my 'worktree' there


## My solution

- Bash script to wrap `git worktree add`
  - If given directory target do not exist: just run normal `git worktree add` as usual
  - If given directory target that already exist (and -f force flag turned on):
    - rename `directory_target` into `tmp-directory_target` (this directory contains our production code and cannot be taken down or turned off)
    - run `git worktree add --no-checkout` (resulting in `directory_target` directory being created with `.git` file as it's only content)
    - move/copy `directory_target/.git` to `tmp-directory_target/.git`
    - delete directory `directory_target`
    - rename `tmp-directory_target` to `directory_target`
- This solution would make the worktree not synchronized with the repository: you must do handpicking after that with `git diff` or `git status` or GNU `diff` or any diff tools or your favorite git gui
- Why bash: almost everyone who use git will use it in some kind of bash-shell-like environment (ex: bash shell in linux, git bash in windows)
- Requirements (should be available on every bash shell):
  - `cat`
  - `echo`
  - `readlink`
  - `realpath` (GNU utility since 2012, might not be preinstalled in very old linux system like debian wheezy)
  - `sed`
  - `pwd`


## Usage

- Execute the script with `-b branch_target` option in your repository (or supply the repository directory path in -r options)
- usage: `git-worktree-create -b branch_target [-d directory_target] [-r repository_target] [-f] [-l linked_files] [-a anchor_relative] [-w wait_seconds] [-v]`
- Options:
  - `-b branch_target` = name of target branch (if not exist it will be created)
  - `-d directory_target` = name of target directory, default to '../{branch_target}'
  - `-r repository_target` = path to repository, default to current directory
  - `-f` = force_flag, must be set to replace existing directory with a branch. in that case a new worktree will be created with content of the target directory
  - `-l linked_files` = multiple files/directories to be softlinked into new worktree (usually for large directory that will never change like './vendor' or './node_modules', softlinked in order to save disk space)
  - `-a anchor_relative` = make the created worktree linked by relative path instead of absolute one, option anchor_relative must be set to a directory name to be used in anchoring them (if not set, default absolute path worktree will be used)
  - `-w wait_seconds` = waiting for ... seconds before executing (default to 5), if you're sure about the operation then just set it to 0
  - `-v` = verbose
- example 1: -b branch_kristian -d /var/www/project1_kristian -r /var/www/project1 -f -l vendor -l node_modules -w 0 -v
  - (-b) use/create branch 'branch_kristian',
  - (-d) checkout in directory '/var/www/project1_kristian',
  - (-r) git repository location in '/var/www/project1',
  - (-f) but the directory '/var/www/project1_kristian' already exist and already have content (programmers have already started working without git), and we do not want to discard his/her edits
  - (-l) in the directory we have 'vendor' and 'node_modules' that we want to softlink in order to save disk space,
  - (-w) wait for 0 seconds (do it immediately)
  - (-v) verbose output on

## Installation

#### Automatic Installation

TODO

#### Manual Installation

TODO

#### Uninstallation

TODO

## Contributing

- Feel free to create issue, pull request, etc if there's anything that can be improved
