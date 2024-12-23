```

           |    |    |
          )_)  )_)  )_)
         )___))___))___)
      )____)____)_____)
   _____|____|____|____\\___    
~~~\___________________________/~~~  
    ~~~    ~    ~~~    ~   ~~~     CaptainArr
    
```
<div align="center">
<h2>CaptainArr Media Server Stack</h2>

[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()
[![Plex](https://img.shields.io/badge/Plex-Media_Server-orange.svg)](https://www.plex.tv/)
[![Contributions Welcome](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)]()

A comprehensive Docker-based media server stack with automated management, monitoring, and organization.

**Disclaimer**: This project is for educational purposes only. It is intended to showcase open-source software concepts and demonstrate server components. Use responsibly and with awareness of any applicable licensing and usage policies.

[Installation](docs/installation.md) •
[Configuration](docs/configuration.md) •
[Services](docs/services.md) •
[Post-Install Setup](docs/post-install.md) •
[Maintenance](docs/maintenance.md) •
[Security](docs/security.md) •
[Troubleshooting](docs/troubleshooting.md)

</div>

## 📋 Quick Start

1. Clone the repository

```bash
git clone https://github.com/bthe0/captainarr.git
cd captainarr
```

### Option 1: Standard Installation

2. Set up environment

```bash
cp .env.example .env
nano .env
```

3. Install and start

```bash
./install.sh
```

### Option 2: Quick Installation with Defaults

2. Install with defaults

```bash
./install.sh --defaults
```

3. Set Plex claim token

```bash
# Get your token from https://www.plex.tv/claim
nano .env
```

4. Start services

```bash
./captainarr.sh start
```

Default Credentials:
- Arr Services (Radarr/Sonarr/etc): admin/admin
- Homarr: admin/Admin123!
- Calibre: admin/admin123
- qBittorrent: admin/adminadmin

**Important**: Change these default passwords as soon as possible after installation!

Once the installation and startup are complete, check [Services](docs/services.md) for more information about accessing and configuring each service.

## 📚 Documentation

- [Installation Guide](docs/installation.md)

  - Prerequisites
  - Installation steps
  - Initial configuration
  - Default installation option

- [Configuration Guide](docs/configuration.md)

  - Environment variables
  - Directory structure
  - Path mappings

- [Services Overview](docs/services.md)

  - Available services
  - Default ports
  - Service descriptions

- [Post-Installation Setup](docs/post-install.md)

  - Step-by-step service configuration
  - Integration setup
  - Media organization

- [Security Guide](docs/security.md)

  - Default credentials
  - Authentication setup
  - Security best practices

- [Maintenance Guide](docs/maintenance.md)

  - Backup and restore
  - Updates
  - Health monitoring

- [Troubleshooting Guide](docs/troubleshooting.md)
  - Common issues
  - Logs and diagnostics
  - Solutions

## 🛠 Basic Usage

```bash
./captainarr.sh <command> [options]

Commands:
  start     - Start all services
  stop      - Stop all services
  restart   - Restart all services
  status    - Show service status
  logs      - View service logs
  update    - Update containers
  backup    - Create backup
  check     - Run health check
  help      - Show help
```

## 👥 Contributing

Contributions are welcome!

## 📝 License

This project is licensed under the MIT License.

---

<div align="center">
Made with ❤️ by bthe0
</div>