# Task 2 - CI/CD Pipeline

## Overview

This task implements a CI/CD pipeline using GitHub Actions that automates the build, test, and deployment process for the application stack. The pipeline triggers on every push to the `main` branch.

## Pipeline Architecture

```
  Developer pushes code to GitHub
              │
              ▼
  ┌───────────────────────┐
  │    GitHub Actions      │
  │    CI/CD Pipeline      │
  └───────────┬───────────┘
              │
     ┌────────┴────────┐
     │  Stage 1: TEST   │
     │  - Install deps   │
     │  - Run lint       │
     │  - Run tests      │
     └────────┬─────────┘
              │ (pass)
     ┌────────┴─────────┐
     │  Stage 2: BUILD   │
     │  - Docker build   │
     │  - Tag images     │
     │  - Push to GHCR   │
     └────────┬─────────┘
              │ (success)
     ┌────────┴─────────┐
     │  Stage 3: DEPLOY  │
     │  - SSH into VM    │
     │  - Pull updates   │
     │  - Restart stack  │
     └────────┬─────────┘
              │
              ▼
     Application running
     on Azure VM (staging)
```

## Pipeline File

The pipeline is defined in `.github/workflows/deploy.yml`

### Stages Explained

#### Stage 1 — Lint & Test

- Sets up Node.js 18
- Installs dependencies for both backend and frontend
- Runs linting checks
- Runs unit tests
- If any check fails, the pipeline stops here

#### Stage 2 — Build & Push Docker Images

- Builds Docker images for: node-api, react-frontend, lamp
- Tags each image with both the commit SHA and `latest`
- Pushes images to GitHub Container Registry (ghcr.io)

#### Stage 3 — Deploy to Staging

- Connects to the Azure VM via SSH
- Pulls the latest code from GitHub
- Pulls the new Docker images
- Restarts the containers using docker-compose
- Cleans up old Docker images

## Required GitHub Secrets

You need to add these secrets in your GitHub repository settings (Settings → Secrets → Actions):

| Secret            | Description                        | Example                     |
| ----------------- | ---------------------------------- | --------------------------- |
| `VM_IP`           | Public IP address of the Azure VM  | `20.123.45.67`              |
| `VM_USER`         | SSH username for the VM            | `azureuser`                 |
| `SSH_PRIVATE_KEY` | Private SSH key for authentication | Contents of `~/.ssh/id_rsa` |

### How to Set Up Secrets

1. Go to your GitHub repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret one by one

For the SSH key:

```bash
# generate a key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/deploy_key -N ""

# copy public key to VM
ssh-copy-id -i ~/.ssh/deploy_key.pub azureuser@<VM_IP>

# the contents of deploy_key (private key) goes into the SSH_PRIVATE_KEY secret
cat ~/.ssh/deploy_key
```

## Rollback Strategy

If a deployment goes wrong, here's how to rollback:

### Option 1: Rollback to Previous Git Commit

```bash
# SSH into the VM
ssh azureuser@<VM_IP>

# go to project directory
cd ~/devops-assignment/task-1

# find the previous working commit
git log --oneline -5

# checkout the previous version
git checkout <previous-commit-hash>

# rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Option 2: Rollback Using Docker Image Tags

Every image is tagged with the git commit SHA. So you can pull a specific version:

```bash
# stop current containers
docker-compose down

# pull specific version of images
docker pull ghcr.io/<owner>/devops-assignment/node-api:<previous-sha>
docker pull ghcr.io/<owner>/devops-assignment/react-frontend:<previous-sha>
docker pull ghcr.io/<owner>/devops-assignment/lamp:<previous-sha>

# update docker-compose to use those tags, then:
docker-compose up -d
```

### Option 3: Quick Rollback Using Git Revert

```bash
# revert the last commit (creates a new commit that undoes changes)
git revert HEAD
git push origin main

# this will trigger the pipeline again with the reverted code
```

### Choosing the Right Approach

| Scenario                 | Recommended Approach               |
| ------------------------ | ---------------------------------- |
| Bad code deployed        | Git revert → auto redeploy         |
| Need immediate fix       | SSH + git checkout previous commit |
| Image-level issue        | Pull previous image tag            |
| Database migration broke | Restore DB backup + git checkout   |

## Testing the Pipeline Locally

You can test the build steps locally before pushing:

```bash
# run tests
cd task-1/mern/backend && npm test
cd task-1/mern/frontend && npm test

# test docker build
cd task-1
docker-compose build

# test full stack
docker-compose up -d
docker-compose ps
```
