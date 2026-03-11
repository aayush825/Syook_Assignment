# Task 1 - On-Premise Application Stack Deployment

## Overview

This task simulates a customer data center deployment where two application stacks (MERN and LAMP) run together on a single server, managed through Docker containers and fronted by an Nginx reverse proxy.

## Architecture

```
                    Client Browser
                         |
                    [Port 80/443]
                         |
                  ┌──────────────┐
                  │  Nginx Proxy │
                  │  (Gateway)   │
                  └──────┬───────┘
                         │
              ┌──────────┴──────────┐
              │                     │
         /app/ route          /legacy/ route
              │                     │
    ┌─────────┴─────────┐    ┌─────┴──────┐
    │   MERN Stack      │    │ LAMP Stack │
    │                    │    │            │
    │  ┌──────────────┐  │    │ ┌────────┐ │
    │  │React Frontend│  │    │ │Apache  │ │
    │  │  (Nginx)     │  │    │ │+ PHP   │ │
    │  └──────┬───────┘  │    │ └───┬────┘ │
    │         │ /api     │    │     │      │
    │  ┌──────┴───────┐  │    │ ┌───┴────┐ │
    │  │ Node.js +    │  │    │ │ MySQL  │ │
    │  │ Express API  │  │    │ │  8.0   │ │
    │  └──────┬───────┘  │    │ └────────┘ │
    │         │          │    └────────────┘
    │  ┌──────┴───────┐  │
    │  │  MongoDB 6   │  │
    │  └──────────────┘  │
    └────────────────────┘
```

## Services

| Service        | Container Name | Port (Host) | Port (Internal) | Description                |
| -------------- | -------------- | ----------- | --------------- | -------------------------- |
| Nginx          | nginx-proxy    | 80          | 80              | Reverse proxy / gateway    |
| Node.js API    | node-api       | 5000        | 5000            | Express backend API        |
| React Frontend | react-frontend | -           | 80              | React app served via Nginx |
| MongoDB        | mongodb        | 27017       | 27017           | NoSQL database for MERN    |
| Apache + PHP   | apache-php     | -           | 80              | PHP application server     |
| MySQL          | mysql-db       | 3306        | 3306            | Relational DB for LAMP     |

## Networking

All containers are connected through a single Docker bridge network called `app-network`. This allows containers to communicate with each other using their service names as hostnames.

**Internal communication flow:**

- `nginx-proxy` → forwards `/app/` requests to `react-frontend:80`
- `nginx-proxy` → forwards `/app/api/` requests to `node-api:5000`
- `nginx-proxy` → forwards `/legacy/` requests to `lamp:80`
- `node-api` → connects to `mongo:27017`
- `lamp` → connects to `mysql:3306`

**Exposed ports on host:**

- `80` - Nginx (main entry point)
- `5000` - Node API (direct access, optional)
- `27017` - MongoDB (for admin access)
- `3306` - MySQL (for admin access)

## How to Run

### Prerequisites

- Ubuntu 22.04 (or similar Linux distro)
- Root / sudo access

### Quick Start (Automated)

```bash
# clone the repo
git clone <repo-url>
cd devops-assignment/task-1

# run the bootstrap script
sudo bash setup.sh
```

The script will:

1. Install Docker and Docker Compose
2. Build all Docker images
3. Start all containers
4. Print access URLs

### Manual Deployment

```bash
# install docker (if not installed)
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl enable docker && sudo systemctl start docker

# build and run
cd task-1
docker-compose build
docker-compose up -d

# check status
docker-compose ps
```

### Verify Deployment

Open in browser:

- **MERN App**: `http://<server-ip>/app/`
- **LAMP App**: `http://<server-ip>/legacy/`
- **Gateway**: `http://<server-ip>/`

### Useful Commands

```bash
# view logs
docker-compose logs -f

# logs for a specific service
docker-compose logs -f node-api

# restart a service
docker-compose restart node-api

# stop everything
docker-compose down

# stop and remove volumes (full cleanup)
docker-compose down -v
```

## Environment Variables

| Variable            | Service  | Default                      | Description               |
| ------------------- | -------- | ---------------------------- | ------------------------- |
| PORT                | node-api | 5000                         | API server port           |
| MONGO_URI           | node-api | mongodb://mongo:27017/merndb | MongoDB connection string |
| MYSQL_HOST          | lamp     | mysql                        | MySQL hostname            |
| MYSQL_USER          | lamp     | root                         | MySQL username            |
| MYSQL_PASSWORD      | lamp     | rootpass123                  | MySQL password            |
| MYSQL_DATABASE      | lamp     | lampdb                       | MySQL database name       |
| MYSQL_ROOT_PASSWORD | mysql    | rootpass123                  | MySQL root password       |

## Data Persistence

Data is persisted using Docker volumes:

- `mongo-data` → MongoDB data at `/data/db`
- `mysql-data` → MySQL data at `/var/lib/mysql`

These volumes survive container restarts and rebuilds.
