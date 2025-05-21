import os
import sys
import subprocess
import time

def main():
    """
    Deploy the CORS fixes to Render.
    
    This script:
    1. Checks if git is installed
    2. Adds all changes to git
    3. Commits the changes
    4. Pushes the changes to the remote repository
    5. Waits for the deployment to complete
    """
    print("Deploying CORS fixes to Render...")
    
    # Check if git is installed
    try:
        subprocess.run(["git", "--version"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Error: Git is not installed or not in PATH.")
        sys.exit(1)
    
    # Add all changes to git
    try:
        subprocess.run(["git", "add", "backend/app/core/cors_middleware.py"], check=True)
        subprocess.run(["git", "add", "backend/app/main.py"], check=True)
        subprocess.run(["git", "add", "backend/app/api/v1/endpoints/auth.py"], check=True)
        subprocess.run(["git", "add", "backend/app/api/v1/endpoints/sensor.py"], check=True)
    except subprocess.CalledProcessError:
        print("Error: Failed to add changes to git.")
        sys.exit(1)
    
    # Commit the changes
    try:
        subprocess.run(["git", "commit", "-m", "Fix CORS issues with change-password endpoint"], check=True)
    except subprocess.CalledProcessError:
        print("Error: Failed to commit changes.")
        sys.exit(1)
    
    # Push the changes to the remote repository
    try:
        subprocess.run(["git", "push"], check=True)
    except subprocess.CalledProcessError:
        print("Error: Failed to push changes to remote repository.")
        sys.exit(1)
    
    print("Changes pushed to remote repository.")
    print("Render will automatically deploy the changes.")
    print("Deployment may take a few minutes to complete.")
    
    # Wait for the deployment to complete
    print("Waiting for deployment to complete...")
    for i in range(60):
        print(f"Waiting... {i+1}/60 seconds", end="\r")
        time.sleep(1)
    
    print("\nDeployment should be complete.")
    print("Check the Render dashboard for deployment status.")
    print("Backend URL: https://envirosense-2khv.onrender.com")

if __name__ == "__main__":
    main()
