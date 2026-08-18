# Git and GitHub Guide

This guide explains how to use Git and GitHub with the `sepsis-mortality` project from VS Code or a terminal.

## 1. Git and GitHub: What Is the Difference?

**Git** is the version-control software installed on your computer. It tracks changes to files and allows you to return to earlier versions.

**GitHub** is the online location where a Git repository can be stored and shared. This project is hosted at:

```text
https://github.com/rkadelva/sepsis-mortality
```

The normal workflow is:

```text
Local folder -> commit -> push -> GitHub
GitHub -> pull -> Local folder
```

A **commit** is a saved checkpoint in local Git history. A **push** uploads local commits to GitHub. A **pull** downloads commits from GitHub into the local folder.

## 2. Install Git

Check whether Git is installed:

```bash
git --version
```

If Git is not installed, download it from:

```text
https://git-scm.com/downloads
```

After installing, restart VS Code and check the version again.

## 3. Configure Git the First Time

Set the name and email that will appear in your commits:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

Check the configuration:

```bash
git config --global --list
```

Use the email associated with your GitHub account if you want commits to be linked to that account.

## 4. Download the Project for the First Time

If the project is not yet on your computer, open a terminal and run:

```bash
git clone https://github.com/rkadelva/sepsis-mortality.git
cd sepsis-mortality
code .
```

Explanation:

- `git clone` downloads the repository and its Git history.
- `cd sepsis-mortality` moves into the project folder.
- `code .` opens that folder in VS Code.

You only need to clone a repository once on a computer.

## 5. Open an Existing Local Project

If the project is already on your computer:

```bash
cd path/to/sepsis-mortality
code .
```

On Linux or macOS, an example might be:

```bash
cd ~/projects/sepsis-mortality
code .
```

On Windows PowerShell, an example might be:

```powershell
cd C:\Users\YourName\projects\sepsis-mortality
code .
```

## 6. Check the Repository Status

Before making changes or synchronizing, run:

```bash
git status
```

This shows:

- the current branch
- modified files
- new untracked files
- files staged for a commit
- whether your branch is ahead of or behind GitHub

To see a shorter status:

```bash
git status --short
```

## 7. Pull Changes from GitHub

Use `git pull` to download new commits from GitHub and apply them to your local folder:

```bash
git pull origin main
```

Explanation:

- `origin` is the name of the GitHub repository connection.
- `main` is the branch being downloaded.

A typical daily workflow starts with:

```bash
cd path/to/sepsis-mortality
git pull origin main
```

Pull before starting work when other people or computers may have changed the repository.

## 8. Make Changes Locally

Edit SAS, Python, Markdown, or other project files in VS Code.

Review the changed files:

```bash
git status
```

Review the actual differences:

```bash
git diff
```

Review one file's difference:

```bash
git diff -- STEP_BY_STEP_GUIDE.md
```

## 9. Stage Changes

Git does not include every changed file in a commit automatically. Stage the files you want to commit.

Stage one file:

```bash
git add code/00_run_all.sas
```

Stage several files:

```bash
git add README.md STEP_BY_STEP_GUIDE.md GIT_GITHUB_GUIDE.md
```

Stage all changes in the repository:

```bash
git add .
```

Review what is staged:

```bash
git diff --cached
```

Only use `git add .` after checking that you do not want to commit temporary files, credentials, large datasets, or unrelated changes.

## 10. Commit Changes Locally

Create a local checkpoint:

```bash
git commit -m "Add Git and GitHub usage guide"
```

Use a message that describes the change. Examples:

```bash
git commit -m "Update SAS reporting workflow"
git commit -m "Add synthetic patient data generator"
git commit -m "Fix rolling quarter summary logic"
```

A commit is local until you push it. Creating a commit does not upload anything to GitHub.

## 11. Push Changes to GitHub

Upload your local commits to GitHub:

```bash
git push origin main
```

After a successful push, open the GitHub repository in a browser to see the changes:

```text
https://github.com/rkadelva/sepsis-mortality
```

The standard local-to-GitHub workflow is:

```bash
git status
git add .
git commit -m "Describe the change"
git push origin main
```

## 12. Complete Pull and Push Workflow

### Download the latest project

```bash
cd path/to/sepsis-mortality
git pull origin main
```

### Make and review changes

Edit files in VS Code, then run:

```bash
git status
git diff
```

### Save the changes locally

```bash
git add .
git commit -m "Describe the change"
```

### Upload the changes

```bash
git push origin main
```

### Update another computer

On another computer that already has the repository:

```bash
cd path/to/sepsis-mortality
git pull origin main
```

## 13. Use Git Through VS Code

VS Code provides a graphical interface for the most common Git actions.

1. Open the project folder in VS Code.
2. Select the **Source Control** icon on the left side.
3. Review the list under **Changes**.
4. Select a changed file to view its diff.
5. Select the `+` icon beside a file to stage it.
6. Enter a commit message in the message box.
7. Select **Commit**.
8. Select **Sync Changes**, **Push**, or **Pull** as needed.

The Source Control panel is an alternative to terminal commands. Both methods use the same Git repository.

## 14. Check the Remote GitHub Repository

Show the GitHub connection configured for the local folder:

```bash
git remote -v
```

Expected output is similar to:

```text
origin  https://github.com/rkadelva/sepsis-mortality.git (fetch)
origin  https://github.com/rkadelva/sepsis-mortality.git (push)
```

Show the current branch:

```bash
git branch --show-current
```

Show recent commits:

```bash
git log --oneline --max-count=10
```

## 15. Work with a Separate Branch

For a larger change, create a branch instead of working directly on `main`:

```bash
git switch -c add-python-documentation
```

Make changes, then commit them:

```bash
git add .
git commit -m "Add Python workflow documentation"
```

Push the new branch to GitHub:

```bash
git push --set-upstream origin add-python-documentation
```

After pushing, GitHub can create a pull request from the branch into `main`.

Return to `main`:

```bash
git switch main
```

Update `main`:

```bash
git pull origin main
```

List local branches:

```bash
git branch
```

## 16. Pull Conflicts

A conflict occurs when both the local copy and GitHub changed overlapping lines in the same file.

Git will identify the conflicted file. Check the status:

```bash
git status
```

Open the file in VS Code. Conflict markers look like this:

```text
<<<<<<< HEAD
Your local version
=======
Version from GitHub
>>>>>>> origin/main
```

Edit the file so it contains the desired final version, and remove the conflict markers. Then stage and commit the resolution:

```bash
git add path/to/conflicted_file
git commit -m "Resolve merge conflict"
git push origin main
```

If you are unsure how to resolve the conflict, do not delete either version. Save a copy of the file and ask for help before committing.

## 17. Push Rejected Because GitHub Is Newer

If `git push` is rejected because the remote branch contains commits that are not local, run:

```bash
git pull --rebase origin main
git push origin main
```

If conflicts occur during the rebase, resolve them in VS Code, then run:

```bash
git add path/to/resolved_file
git rebase --continue
git push origin main
```

To cancel an unfinished rebase:

```bash
git rebase --abort
```

## 18. Files That Should Usually Not Be Committed

Do not commit:

- passwords, API keys, tokens, or credentials
- production patient-identifying data
- temporary files
- local Python virtual environments
- operating-system files
- very large generated outputs unless the project specifically requires them

Check what Git will include before committing:

```bash
git status --short
git diff --cached --stat
```

Synthetic data can be committed if it is intentionally part of the project and contains no real patient information. Production data should remain in approved secure storage.

## 19. Authentication

GitHub may require authentication when pushing. Depending on your organization, use one of these approved methods:

- GitHub CLI authentication
- a personal access token
- SSH keys
- VS Code's GitHub sign-in

Never place a password or token directly into a script or commit. Do not commit files containing secrets.

## 20. Useful Safety Commands

See local changes without modifying anything:

```bash
git diff
```

See staged changes without modifying anything:

```bash
git diff --cached
```

See the last commit:

```bash
git show --stat --oneline HEAD
```

See whether local and remote branches differ:

```bash
git fetch origin
git status
```

Discard unstaged changes to one file only:

```bash
git restore path/to/file
```

Use `git restore` carefully. It removes local unstaged edits to that file.

## 21. Recommended Workflow for This Project

For normal work on the sepsis project:

```bash
cd path/to/sepsis-mortality
git pull origin main

# Edit SAS, Python, or Markdown files.

python3 -m compileall -q python_scripts/sepsis_pipeline
PYTHONPATH=python_scripts python3 -m sepsis_pipeline

git status
git diff
git add path/to/changed_files
git commit -m "Describe the tested change"
git push origin main
```

For a new computer:

```bash
git clone https://github.com/rkadelva/sepsis-mortality.git
cd sepsis-mortality
code .
```

For an existing local copy:

```bash
cd path/to/sepsis-mortality
git pull origin main
```
