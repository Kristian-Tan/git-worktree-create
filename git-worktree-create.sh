#! /bin/bash

OPTIND=1 # Reset in case getopts has been used previously in the shell.

# boilerplate
set -o errexit # exit when any command return non-zero exit code
set -o nounset # exit when using undeclared variables
exit_on_error() {
    if test $# -eq 1; then
        echo ">>> $1"
    fi
    exit 1
}

# default argument value
branch_target=""
directory_target=""
repository_target=`pwd`
force_flag=0
linked_files=() # array, see https://stackoverflow.com/a/20761893/3706717
#anchor_relative=""
wait_seconds=5
verbose=0

# read arguments from getopts https://wiki.bash-hackers.org/howto/getopts_tutorial https://stackoverflow.com/a/14203146/3706717
while getopts "hb:d:r:fl:w:v" opt; do
    case "$opt" in
    h)
        cat << EOF
usage: -b branch_target [-d directory_target] [-r repository_target] [-f] [-l linked_files] [-w wait_seconds] [-v]
  -b branch_target = name of target branch (if not exist it will be created)
  -d directory_target = name of target directory, default to '../{branch_target}'
  -r repository_target = path to repository, default to current directory
  -f = force_flag, must be set to replace existing directory with a branch. in that case a new worktree will be created with content of the target directory
  -l linked_files = multiple files/directories to be softlinked into new worktree (usually for large directory that will never change like './vendor' or './node_modules', softlinked in order to save disk space)
  -w wait_seconds = waiting for ... seconds before executing (default to 5), if you're sure about the operation then just set it to 0
  -v = verbose
example 1: -b branch_kristian -d /var/www/project1_kristian -r /var/www/project1 -f -l vendor -l node_modules -w 0 -v
  (-b) use/create branch 'branch_kristian',
  (-d) checkout in directory '/var/www/project1_kristian',
  (-r) git repository location in '/var/www/project1',
  (-f) but the directory '/var/www/project1_kristian' already exist and already have content (programmers have already started working without git), and we do not want to discard his/her edits
  (-l) in the directory we have 'vendor' and 'node_modules' that we want to softlink in order to save disk space,
  (-w) wait for 0 seconds (do it immediately)
  (-v) verbose output on
EOF
#-a anchor_relative = make the created worktree linked by relative path instead of absolute one, option anchor_relative must be set to a directory name to be used in anchoring them (if not set, default absolute path worktree will be used)
        exit 0
        ;;
    b)  branch_target=$OPTARG
        ;;
    d)  directory_target=$OPTARG
        ;;
    r)  repository_target=$OPTARG
        ;;
    f)  force_flag=1
        ;;
    l)  linked_files+=("$OPTARG")
        ;;
    #a)  anchor_relative=$OPTARG
    #    ;;
    w)  wait_seconds=$OPTARG
        ;;
    v)  verbose=1
        ;;
    esac
done



# declare verbose output function

# @param string $1
#   Input string that should be printed if verbose is on
verbose_output()
{
  if test $verbose -eq 1; then
    { printf '>>> %s ' "$@"; echo; } 1>&2
  fi
}

# fill argument with default value
if test "$branch_target" = ""; then
  echo ">>> please set branch_target!"
  exit 1
fi
if test "$directory_target" = ""; then
  directory_target="../$branch_target"
fi
if test -d $directory_target -a $force_flag -eq 0; then
  echo ">>> directory $directory_target exist! please use force_flag if you want to make a worktree with content of existing directory"
  exit 2
fi
if test ! -d $directory_target -a $force_flag -eq 1; then
  echo ">>> directory $directory_target does not exist! please do not use force_flag"
  exit 3
fi
# if test "$anchor_relative" = "."; then
#   verbose_output "testing if \"`readlink -f $anchor_relative`\" is equal to \"`readlink -f $repository_target`\""
#   if test "`readlink -f $anchor_relative`" == "`readlink -f $repository_target`"; then
#     verbose_output "it's equal, so anchor is set to parent directory"
#     anchor_relative="$repository_target/.."
#   else
#     verbose_output "it's not equal, so anchor is set to current directory"
#     anchor_relative=`pwd`
#   fi
# fi

# show to user
verbose_output "branch_target: '$branch_target'"
verbose_output "directory_target: '$directory_target'"
verbose_output "repository_target: '$repository_target'"
verbose_output "force_flag: '$force_flag'"
verbose_output "linked_files: '${linked_files[@]}'"
#verbose_output "anchor_relative: '$anchor_relative'"
verbose_output "wait_seconds: '$wait_seconds'"

echo ">>> executing in $wait_seconds seconds... (press ctrl+c to abort)"
sleep $wait_seconds
echo ">>> executing..."

verbose_output "set directory target to absolute path"
verbose_output "  \$ directory_target=`readlink -f $directory_target`"
directory_target=`readlink -f $directory_target`

verbose_output "change directory to repository"
verbose_output "  \$ cd \"$repository_target\""
cd "$repository_target"

verbose_output "create branch if not exist (please ignore error)"
verbose_output "  \$ git branch $branch_target || true"
git branch $branch_target || true

if test $force_flag -eq 1; then
  verbose_output "mode: force replace"
  
  verbose_output "rename target directory"
  verbose_output "  \$ mv \"$directory_target\" \"$directory_target-tmp\""
  mv "$directory_target" "$directory_target-tmp"

  verbose_output "create worktree"
  verbose_output "  \$ git worktree add --no-checkout \"$directory_target\" $branch_target"
  git worktree add --no-checkout "$directory_target" $branch_target

  verbose_output "move .git file from newly created worktree to target directory"
  verbose_output "  \$ mv \"$directory_target/.git\" \"$directory_target-tmp/.git\""
  mv "$directory_target/.git" "$directory_target-tmp/.git"

  verbose_output "delete generated worktree directory (should be empty)"
  verbose_output "  \$ rmdir \"$directory_target\""
  rmdir "$directory_target"

  verbose_output "rename target directory back"
  verbose_output "  \$ mv \"$directory_target-tmp\" \"$directory_target\""
  mv "$directory_target-tmp" "$directory_target"

  echo ">>> operation finished, you should go to newly created worktree and check if there are unstaged changes"
  echo ">>> delete worktree with 'git worktree remove --force $branch_target'"
else
  verbose_output "mode: new worktree"
  
  verbose_output "create worktree"
  verbose_output "  \$ git worktree add \"$directory_target\" $branch_target"
  git worktree add "$directory_target" $branch_target
fi

verbose_output "deleting linked files"
for val in ${linked_files[@]+"${linked_files[@]}"}; do
  verbose_output "  \$ rm -rf \"$directory_target/$val\""
  rm -rf "$directory_target/$val"
done

verbose_output "linking files"
for val in ${linked_files[@]+"${linked_files[@]}"}; do
  verbose_output "  getting relative path"
  path_relative=`realpath --relative-to="$directory_target" "$val"`
  verbose_output "  \$ ln -s \"$path_relative\" \"$directory_target/$val\""
  ln -s "$path_relative" "$directory_target/$val"
done

# if test "$anchor_relative" != ""; then
#
#   verbose_output "converting worktree reference to use relative path instead of absolute path"
#
#   anchor_relative=`readlink -f $anchor_relative`
#   verbose_output "  anchor relative to: $anchor_relative"
#
#   absolute_repository=`readlink -f $repository_target`
#   verbose_output "  repository absolute path is: $absolute_repository"
#
#   absolute_worktree=`readlink -f $directory_target`
#   verbose_output "  worktree absolute path is: $absolute_worktree"
#
#   temp1_worktree_to_anchor=`realpath --relative-to="$absolute_worktree" "$anchor_relative"`
#   temp1_repo_to_worktree=`realpath --relative-to="$temp1_worktree_to_anchor" "$absolute_worktree"`
#   path_repository_to_worktree="$temp1_worktree_to_anchor/$temp1_repo_to_worktree"
#   verbose_output "  relative path from repository to worktree is: $path_repository_to_worktree"
#
#   temp2_repo_to_anchor=`realpath --relative-to="$absolute_repository" "$anchor_relative"`
#   temp2_worktree_to_repo=`realpath --relative-to="$temp2_repo_to_anchor" "$absolute_repository"`
#   path_worktree_to_repo="$temp2_repo_to_anchor/$temp2_worktree_to_repo"
#   verbose_output "  relative path from worktree to repository is: $path_worktree_to_repo"
#
#   verbose_output "  \$ sed -i \"s+$absolute_repository+$path_worktree_to_repo+g\" \"$directory_target/.git\""
#   sed -i "s+$absolute_repository+$path_worktree_to_repo+g" "$directory_target/.git"
#
#   worktree_link_content="$(cat $directory_target/.git)"
#   worktree_link_content="${worktree_link_content/gitdir: /}" # replace "gitdir: " with ""
#   worktree_link_content=`readlink -f $worktree_link_content`
#   verbose_output "  gitdir points to: $worktree_link_content"
#
#   verbose_output "  \$ sed -i \"s+$absolute_worktree+$path_repository_to_worktree+g\" \"$worktree_link_content/gitdir\""
#   sed -i "s+$absolute_worktree+$path_repository_to_worktree+g" "$worktree_link_content/gitdir"
# fi


echo ">>> done; to see documentation about git worktree, visit https://git-scm.com/docs/git-worktree"
echo ">>> "
echo ">>> to list all existing worktree, use 'git worktree list' "
echo ">>> "
echo ">>> to delete/remove worktree, use 'git worktree remove <worktree>', ex: "
echo ">>> git worktree remove --force $directory_target "
echo ">>>   flag --force will delete your worktree even if there are untracked/modified files"
echo ">>> "
echo ">>> to move worktree, use 'git worktree move <worktree> <new-path>', ex: "
echo ">>> git worktree move $directory_target $directory_target-new "
