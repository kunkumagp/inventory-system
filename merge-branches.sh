#!/bin/bash

# Script to merge a specified branch into dev and main branches with a custom commit message for dev

# Prompt for the branch name to merge
echo "Enter the name of the branch you want to merge:"
# read CURRENT_BRANCH
read BRANCH_TO_MERGE

# Prompt for a custom commit message for the dev branch
echo "Enter a custom commit message for merging into $DEV_BRANCH (leave blank for default):"
read CUSTOM_COMMIT_MESSAGE

# Add a tag for the main branch
echo "Enter a tag name for the main branch (e.g., v1.0.0):"
read TAG_NAME


# Define target branches
DEV_BRANCH="dev"
MAIN_BRANCH="main"

# Function to merge the current branch into a target branch
merge_branch() {
    TARGET_BRANCH=$1
    CURRENT_BRANCH=$2
    CUSTOM_MESSAGE=$3

    echo "Switching to branch $TARGET_BRANCH..."
    git checkout $TARGET_BRANCH || exit 1

    echo "Pulling latest changes from $TARGET_BRANCH..."
    git pull origin $TARGET_BRANCH || exit 1

    echo "Merging $CURRENT_BRANCH into $TARGET_BRANCH..."
    if [[ $TARGET_BRANCH == $DEV_BRANCH && -n $CUSTOM_MESSAGE ]]; then
        git merge --no-ff -m "$CUSTOM_MESSAGE" $CURRENT_BRANCH || exit 1
    else
        git merge $CURRENT_BRANCH || exit 1
    fi

    echo "Pushing merged changes to remote $TARGET_BRANCH..."
    git push origin $TARGET_BRANCH || exit 1
}

# Ensure the specified branch is up-to-date
echo "Switching to branch $BRANCH_TO_MERGE..."
git checkout $BRANCH_TO_MERGE || exit 1

# Check for uncommitted changes
echo "Checking for uncommitted changes..."
if ! git diff-index --quiet HEAD --; then
    echo "Found uncommitted changes. Committing them as 'latest changes'..."
    git add -A || exit 1
    git commit -m "latest changes" || exit 1
else
    echo "No uncommitted changes found."
fi

# Check if the branch exists on origin and pull/push accordingly
echo "Checking if branch $BRANCH_TO_MERGE exists on origin..."
if git ls-remote --exit-code --heads origin $BRANCH_TO_MERGE > /dev/null 2>&1; then
    echo "Branch $BRANCH_TO_MERGE exists on origin. Pulling latest changes..."
    git pull origin $BRANCH_TO_MERGE || exit 1
else
    echo "Branch $BRANCH_TO_MERGE does not exist on origin. Pushing it now..."
    git push -u origin $BRANCH_TO_MERGE || exit 1
fi


# Reset 'soft' to squash commits into one
echo "Squashing commits into one..."
git reset --soft $(git merge-base $BRANCH_TO_MERGE $DEV_BRANCH)
git commit -m "Squashed commits before merging" || exit 1
git push origin $BRANCH_TO_MERGE --force || exit 1
echo "Branch $BRANCH_TO_MERGE is ready for merging."


# Merge into dev branch with a custom commit message
merge_branch $DEV_BRANCH $BRANCH_TO_MERGE "$CUSTOM_COMMIT_MESSAGE"

# Merge into main branch without a custom commit message
merge_branch $MAIN_BRANCH $DEV_BRANCH


echo "Creating a tag $TAG_NAME for the main branch..."
git tag -a $TAG_NAME -m "Release version $TAG_NAME" || exit 1

echo "Pushing the tag $TAG_NAME to the remote repository..."
git push origin $TAG_NAME || exit 1

# Optional: Delete the specified branch locally and remotely
read -p "Do you want to delete the branch $BRANCH_TO_MERGE? (y/n): " DELETE_BRANCH
if [[ $DELETE_BRANCH == "y" ]]; then
    echo "Deleting branch $BRANCH_TO_MERGE locally..."
    git branch -d $BRANCH_TO_MERGE || exit 1

    echo "Deleting branch $BRANCH_TO_MERGE remotely..."
    git push origin --delete $BRANCH_TO_MERGE || exit 1
fi

echo "Merge process completed successfully!"