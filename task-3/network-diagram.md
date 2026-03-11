# Network Architecture

## System-Level Network Diagram

```
  ┌─────────────────┐
  │   IoT Devices   │
  │  (Sensors, Tags)│
  └────────┬────────┘
           │ BLE (Bluetooth Low Energy)
           ▼
  ┌─────────────────┐
  │   BLE Gateway   │
  │   (Edge Device) │
  └────────┬────────┘
           │ TCP/IP (Port 8080)
           ▼
  ┌─────────────────────────────────────────────────┐
  │              Azure VM (Application Server)       │
  │                                                  │
  │  Port 80/443                                     │
  │  ┌──────────────────────────┐                    │
  │  │  Nginx Reverse Proxy     │                    │
  │  │  (SSL Termination)       │                    │
  │  └─────────┬────────────────┘                    │
  │            │                                     │
  │    ┌───────┴───────┐                             │
  │    │               │                             │
  │    ▼               ▼                             │
  │  /app/          /legacy/                         │
  │    │               │                             │
  │  ┌─┴──────┐     ┌──┴────────┐                   │
  │  │ React  │     │ Apache    │                    │
  │  │ :80    │     │ + PHP :80 │                    │
  │  └───┬────┘     └─────┬─────┘                   │
  │      │                │                          │
  │  ┌───┴─────────┐  ┌──┴──────────┐               │
  │  │ Node.js API │  │   MySQL     │               │
  │  │  :5000      │  │   :3306     │               │
  │  └───┬─────────┘  └─────────────┘               │
  │      │                                           │
  │  ┌───┴─────────┐                                 │
  │  │  MongoDB    │                                 │
  │  │  :27017     │                                 │
  │  └─────────────┘                                 │
  │                                                  │
  └──────────────────────────────────────────────────┘
```

## Protocol & Port Mapping

| Source           | Destination    | Protocol   | Port   | Direction         |
| ---------------- | -------------- | ---------- | ------ | ----------------- |
| Client (Browser) | Nginx          | HTTP/HTTPS | 80/443 | Inbound           |
| IoT Device       | BLE Gateway    | BLE        | -      | Wireless          |
| BLE Gateway      | App Server     | TCP        | 8080   | Inbound           |
| Nginx            | React Frontend | HTTP       | 80     | Internal (Docker) |
| Nginx            | Node.js API    | HTTP       | 5000   | Internal (Docker) |
| Nginx            | Apache+PHP     | HTTP       | 80     | Internal (Docker) |
| Node.js API      | MongoDB        | TCP        | 27017  | Internal (Docker) |
| Apache+PHP       | MySQL          | TCP        | 3306   | Internal (Docker) |
| Admin            | VM             | SSH        | 22     | Inbound           |

## Docker Network

All containers run on a single Docker bridge network (`app-network`).

- Containers communicate using service names as DNS hostnames
- Only port 80 (Nginx) is exposed to the outside world
- Database ports are only accessible within the Docker network

## Firewall Rules (Simplified)

```
INBOUND:
  ALLOW  TCP 22   (SSH - rate limited)
  ALLOW  TCP 80   (HTTP)
  ALLOW  TCP 443  (HTTPS)
  DENY   ALL      (everything else)

OUTBOUND:
  ALLOW  ALL      (for package updates, etc.)
```

Internal container-to-container traffic flows through the Docker bridge network and is not subject to host-level firewall rules.
