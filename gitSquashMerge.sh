#!/bin/bash

############################ Description #########################
# This script mirror the github merge-squash-commit pull request
# to install:
# 1. save the script in HOME
# 2. Open ~/.bashrc
# 3. Append alias sqm='~/.gitSquashMerge.sh'
# 4. chomod 777 ~/.gitSquashMerge.sh
################################################################


#For newer git: featureBranch=$(git branch --show-current)
featureBranch=$(git status | grep 'On branch' | awk -F' ' '{print $3}')
developBranch=main
tempBranch=$featureBranch$(date +%s)

# Check current branch.  Switch to case insensitive
shopt -s nocasematch
if [[ "$featureBranch" = "master" ]] || [[ "$featureBranch" = "develop" ]] || [[ "$featureBranch" = "main" ]]; then
	echo "The current branch is" $featureBranch
	echo "Dangerous! Aborted!  Swich to feature branch and rerun."
	exit
fi
shopt -u nocasematch

# Check for uncommit changes
output=$(git status)
if ! echo "$output" | grep -q 'nothing to commit, working tree clean'; then
  echo "local changes are found.  Please commit first"
  exit
fi




############################ Main Logic #########################
# Upldate develop branch
# Branch out a new temp branch, that has the latest
# Squash and merge the feature branch to the new branch
# switch the branch name between the feature and new branch
# Delete the branch with multiple commits
###################################################################


switch_to_branch() {
	local branch="$1"  # Access the parameter with $1
	echo "Switch to " $branch
	git checkout $branch
	if [ $? -ne 0 ]; then
		echo "Fail to git checkout " $branch
		exit
  	fi
}

git_pull_and_check () {
	git pull

	#Is return value = 0 === NO_ERROR
	if [ $? -ne 0 ]; then
  		echo "Fail to git pull on" $developBranch ", likely you have local changes, if so: git reset --hard HEAD" 
  		exit
	fi
}


echo "Starting: Squash all commit(s) at" $featureBranch ", then merge to" $developBranch

commitMessages=$(git log --oneline | tr '\n' ', ')

switch_to_branch $developBranch

git_pull_and_check

# Create a temp branch to make all the change, which by squashing
git checkout -b $tempBranch
git merge --squash $featureBranch
if [ $? -ne 0 ]; then
	echo "Something wrong with git merge --squash" $featureBranch
	echo "likely conflict is found between" $featureBranch "and" $developBranch
	git checkout $featureBranch
	git branch -D $tempBranch
	echo "Rolled back all action! Aborted with no modification!"
	exit
fi

# Commit the squashed new commit
git commit -m "$commitMessages"
if [ $? -ne 0 ]; then
	echo "Something wrong with git commit"
	echo "Likely caused by funny content in the commit message"
	git checkout $featureBranch
	git branch -D $tempBranch
	echo "Rolled back all action! Aborted with no modification!"
	exit
fi

git push --force --set-upstream origin $tempBranch
if [ $? -ne 0 ]; then
	echo "Something wrong when pushing the temperary branch, git push" $tempBranch
	echo "Manually run git push --force --set-upstream origin" $tempBranch
	echo "or"
	echo "Delete the temperary branch" $tempBranch
	echo "Your work is still safe at" $featureBranch
	exit
fi

########################## Note ###########################
# At this point, the temp Branch is found in local and remote
# The original feature banch can be deleted
# Rename the temp branch to the feature branch
############################################################

git branch -D $featureBranch
git push origin --delete $featureBranch

git branch -m $featureBranch
git push origin -u $featureBranch

git push origin --delete $tempBranch

echo "Good - Done"