# DevOps Field Engineer Assignment

## What This Is

A complete on-premise application stack deployment demonstrating DevOps skills including containerization, CI/CD, networking, and security hardening. The project deploys a MERN stack and a LAMP stack side by side on a single server using Docker, with Nginx as a reverse proxy routing traffic to both applications.

## Architecture Overview

```
Internet
   │
   ▼ (Port 80/443)
┌──────────────┐
│  Nginx Proxy │
└──────┬───────┘
       │
  ┌────┴────┐
  │         │
/app     /legacy
  │         │
  ▼         ▼
MERN      LAMP
Stack     Stack
```

**MERN Stack**: React frontend + Node.js/Express API + MongoDB  
**LAMP Stack**: Apache + PHP + MySQL

Both stacks run as Docker containers on the same host, communicating over a Docker bridge network.

## Repository Structure

```
devops-assignment/
│
├── task-1/                         # Application Stack Deployment
│   ├── docker-compose.yml          # All services definition
│   ├── setup.sh                    # One-command bootstrap script
│   ├── nginx/
│   │   └── nginx.conf              # Reverse proxy configuration
│   ├── mern/
│   │   ├── backend/                # Node.js + Express API
│   │   │   ├── server.js
│   │   │   ├── package.json
│   │   │   └── Dockerfile
│   │   └── frontend/               # React app
│   │       ├── src/
│   │       ├── public/
│   │       ├── package.json
│   │       └── Dockerfile
│   ├── lamp/
│   │   └── php-app/                # PHP application
│   │       ├── index.php
│   │       ├── health.php
│   │       └── Dockerfile
│   └── README.md
│
├── task-2/                         # CI/CD Pipeline
│   ├── .github/
│   │   └── workflows/
│   │       └── deploy.yml          # GitHub Actions pipeline
│   └── README.md
│
├── task-3/                         # Networking & Security
│   ├── firewall.sh                 # UFW firewall rules
│   ├── nginx-secure.conf           # Nginx with SSL + security headers
│   ├── network-diagram.md          # Network architecture diagram
│   └── security-checklist.md       # Security hardening checklist
│
├── screenshots/                    # Deployment screenshots
└── README.md                       # This file
```

## Quick Start

### Prerequisites

- Ubuntu 22.04 server (Azure VM or any Linux machine)
- Git installed
- SSH access

### Deploy in One Command

```bash
git clone <this-repo-url>
cd devops-assignment/task-1
sudo bash setup.sh
```

This will install Docker, build all images, and start the full stack.

### Access the Application

| URL                          | Application  |
| ---------------------------- | ------------ |
| `http://<server-ip>/`        | Landing page |
| `http://<server-ip>/app/`    | MERN Stack   |
| `http://<server-ip>/legacy/` | LAMP Stack   |

## Tasks Breakdown

### Task 1 — Application Stack Deployment

- Docker containers for both MERN and LAMP stacks
- Nginx reverse proxy routing `/app/` and `/legacy/`
- Single `docker-compose.yml` to manage all services
- Bootstrap script for one-command deployment

### Task 2 — CI/CD Pipeline

- GitHub Actions pipeline with 3 stages: Test → Build → Deploy
- Automatic deployment to staging server on push to `main`
- Docker images pushed to GitHub Container Registry
- Rollback strategy documented

### Task 3 — Networking & Security

- Network architecture with protocol/port mapping
- UFW firewall script (only required ports open)
- Nginx with SSL/TLS, rate limiting, and security headers
- Security hardening checklist (SSH, logging, auto-updates)

## Technology Stack

| Component        | Technology              |
| ---------------- | ----------------------- |
| Frontend         | React 18, Nginx         |
| Backend API      | Node.js 18, Express     |
| NoSQL Database   | MongoDB 6               |
| PHP Application  | PHP 8.2, Apache         |
| SQL Database     | MySQL 8.0               |
| Reverse Proxy    | Nginx 1.25              |
| Containerization | Docker, Docker Compose  |
| CI/CD            | GitHub Actions          |
| Cloud            | Azure VM (Ubuntu 22.04) |
| Security         | UFW, SSL/TLS, fail2ban  |

## Useful Commands

```bash
# check container status
cd task-1 && docker-compose ps

# view logs
docker-compose logs -f

# restart a service
docker-compose restart node-api

# full shutdown
docker-compose down

# full shutdown + remove data
docker-compose down -v

# rebuild everything
docker-compose up -d --build
```
