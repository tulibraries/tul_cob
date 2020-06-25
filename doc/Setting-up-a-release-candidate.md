Setting Up A Release Candidate
===

This document describes the process for staging a new release (release candidate). Both staging and deployment are triggered by creating a tagged release.  Thus, at its most basic this is all that is required (see [Deployment Process](deployment-process.md#stage-deployments)) 

However there are several scenarios that have to be considered.

## Release is based on HEAD of main branch

This the easiest of all scenarios and only requires for us to generated a release based on the main branch. 


## Release is based on a commit hash that is on the main branch

This scenario is when we can point to a commit hash on the main branch and basically reference that as the tagged release.

If the commit hash is a recent commit then [when creating a new release](new-release-process.md) instead of choosing the main branch as the target, click on the recent commits tab and find click on recent commit.

Otherwise you will need to create a new branch that you push up and choose that branch.

### Creating a release candidate branch based on a commit.
* `git fetch origin main`
* `git checkout -b release-v1.7.0 <commit-hash>`
* `git push origin release-v1.7.0`

(Note that it doesn't really matter what you call the branch)

## Release is composed of specific commits that need to be git cherry-picked

This is the most complicated scenario but it's basically just a variation of a release based on a commit.

In this scenario we cannot just use the `HEAD` or some other commit reference to create our new release candidate branch.

Once the release branch is created and pushed up you may proceed with the release and target that release branch instead of the main branch.

### Creating a release candidate branch based on a commit.
Assuming that the currently deployed release is `v1.7.0` and we are setting up `v1.7.1` and we want to deploy some changes referenced by `<commit-hash-1>` and `<commit-hash-2>`

* `git fetch origin --tags`
* `git checkout -b release-v1.7.1 v1.7.0`
* `git cherry-pick <commit-hash-1>`
* `git cherry-pick <commit-hash-2>`
* ... (you may need to fix some merge conflicts)
* `git push origin release-v1.7.1`
