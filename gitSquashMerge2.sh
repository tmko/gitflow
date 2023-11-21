#!/bin/bash

############################ Description #########################
# This script mirror the github merge-squash-commit pull request
# to install:
# 1. save the script in HOME
# 2. Open ~/.bashrc
# 3. Append alias sqm='~/.gitSquashMerge.sh'
# 4. chomod 777 ~/.gitSquashMerge.sh
################################################################


getCurrentBranch() {
	# return the name of current branch
	# exit #lineNumber, if banch is main, develop, master, release etc
	# exit #lineNumber, if error occur
	
	dangerousBranches=("develop" "master" "release" "main2")
	featureBranch=$(git status | grep 'On branch' | awk -F' ' '{print $3}')

	if [ $? -ne 0 ]; then
		echo "Error at git status"
		exit 23
  	fi 

	for dangerousBranch in "${dangerousBranches[@]}"; do
		prefix="${featureBranch:0:${#dangerousBranch}}"
		lowercasePrefix="${prefix,,}"
	    
	    if [ "$prefix" == "$dangerousBranch" ]; then
	    	echo "The current branch is dangerous" $featureBranch 
    		exit 34
		fi
	done

	echo $featureBranch
}

isSyncWithRemote() {
	result=$(git diff origin)
	if [ $? -ne 0 ]; then
		echo "Error at git diff origin"
		exit 43
  	fi 

	if [ ! "$result" ]; then
		#result is empty, so no different found
		return 0;
	fi
	return 1;
}

getBrach() {
	local branch=$1
	gitResult=$(git checkout $branch | git pull)
	if [ $? -ne 0 ]; then
		echo "Error at git checkout" $branch
		exit 43
  	fi 
}


getCurrentBranch

isSyncWithRemote

echo $?

getBrach test1

getCurrentBranch