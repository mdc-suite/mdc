# Contributing to MDC

### Start the development

The main branches of this repository are:

*   The **master** branch contains the different releases of MDC. This means that you should **NOT** commit, push or merger on master branch.
*   The **develop** branch integrates the latest new features that are currently being thoroughly tested. This means that it contains the latest version of the code.

If you want to contribute to this repository, you should follow the following steps:

*   Clone the repository on develop branch (`git clone <url> -b develop`)
*   Create a new branch from develop one to start the development of your code --new feature, code refactor, bug fix, etc-- (`git checkout -b <new-branch-name>`). Please, use meaningful names for you branches 
*   Please, also check frequently if there has been changes in the repository. To do so, from your branch with all changes committed, do: 
    *   Remote repository synchronization: `git fetch --all`
    *   If there is anything new, include these changes by rebasing develop: `git rebase origin/develop <your-branch-name>`
    *   If you have done the rebase, you will need to force push: `git push -f origin <your-branch-name>`
*   Once you have fulfilled all these steps, if you want to merge your changes in develop, you can create a pull request with any of the admins as reviewers.

### How to prepare a pull request

When preparing a pull request, please be sure that you fulfill the following steps:

*   Your branch has correctly rebased develop branch
*   You have updated the release_notes file
*   You put a meaningful name to your pull request
*   Describe in detail the new feature or the bug fixed in this branch
*   Set as a reviewer one of the repository admins

### How to fill a bug report

When filling a bug report, please be sure that you fulfill the following steps:

*   Select a meaningful title
*   In the description, include:
   *   Commit you are referring to
   *   Detailed description of your problem
   *   Project to replicate the error/bug

After this, the admin will assign the bug to the person in charge of that part.

