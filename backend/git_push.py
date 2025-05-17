import subprocess
import argparse
import os
import sys

def run_command(command, verbose=True):
    """Run a shell command and return the output"""
    if verbose:
        print(f"Running: {command}")
    
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        universal_newlines=True
    )
    
    stdout, stderr = process.communicate()
    
    if verbose:
        if stdout:
            print(stdout)
        if stderr:
            print(stderr)
    
    return process.returncode, stdout, stderr

def git_status():
    """Check the status of the Git repository"""
    return run_command("git status")

def git_add(files=None):
    """Add files to the Git staging area"""
    if files:
        if isinstance(files, list):
            files = " ".join(files)
        command = f"git add {files}"
    else:
        command = "git add ."
    
    return run_command(command)

def git_commit(message):
    """Commit changes to the Git repository"""
    return run_command(f'git commit -m "{message}"')

def git_push(remote="origin", branch="main"):
    """Push changes to the remote Git repository"""
    return run_command(f"git push {remote} {branch}")

def git_pull(remote="origin", branch="main"):
    """Pull changes from the remote Git repository"""
    return run_command(f"git pull {remote} {branch}")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Git commit and push helper")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Check Git status")
    
    # Add command
    add_parser = subparsers.add_parser("add", help="Add files to Git staging area")
    add_parser.add_argument("files", nargs="*", help="Files to add (default: all)")
    
    # Commit command
    commit_parser = subparsers.add_parser("commit", help="Commit changes")
    commit_parser.add_argument("-m", "--message", required=True, help="Commit message")
    commit_parser.add_argument("-a", "--add", action="store_true", help="Add all files before committing")
    
    # Push command
    push_parser = subparsers.add_parser("push", help="Push changes to remote")
    push_parser.add_argument("-r", "--remote", default="origin", help="Remote name (default: origin)")
    push_parser.add_argument("-b", "--branch", default="main", help="Branch name (default: main)")
    
    # Pull command
    pull_parser = subparsers.add_parser("pull", help="Pull changes from remote")
    pull_parser.add_argument("-r", "--remote", default="origin", help="Remote name (default: origin)")
    pull_parser.add_argument("-b", "--branch", default="main", help="Branch name (default: main)")
    
    # All-in-one command
    all_parser = subparsers.add_parser("all", help="Add, commit, and push in one command")
    all_parser.add_argument("-m", "--message", required=True, help="Commit message")
    all_parser.add_argument("-r", "--remote", default="origin", help="Remote name (default: origin)")
    all_parser.add_argument("-b", "--branch", default="main", help="Branch name (default: main)")
    all_parser.add_argument("files", nargs="*", help="Files to add (default: all)")
    
    args = parser.parse_args()
    
    if args.command == "status":
        git_status()
    elif args.command == "add":
        git_add(args.files)
    elif args.command == "commit":
        if args.add:
            git_add()
        git_commit(args.message)
    elif args.command == "push":
        git_push(args.remote, args.branch)
    elif args.command == "pull":
        git_pull(args.remote, args.branch)
    elif args.command == "all":
        if args.files:
            git_add(args.files)
        else:
            git_add()
        git_commit(args.message)
        git_push(args.remote, args.branch)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
