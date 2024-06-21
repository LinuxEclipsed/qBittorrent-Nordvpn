# qBittorrent and NordVPN Docker

## Introduction

I created this container to bundle qBittorrent and NordVPN for my arr suite. Originally, I was using a dedicated VM for downloads even though the rest of the suite was a docker container. The reason I did this was I needed to use NordVPN and have it auto start at VM boot. This has solved the problem. This is still in testing and needs a lot of trimming on the Dockerfile but still gets the job done.

## NordVPN token setup

In order to use this container you will need to pass the NordVPN token. This can be created in your NordVPN dashboard either as a 30 day or unlimited token. I recommend creating the unlimited as you wont need to recreate the container. Documentation can be found [here](https://support.nordvpn.com/hc/en-us/articles/20286980309265-How-to-use-a-token-with-NordVPN-on-Linux)

## Build

Until the container is uploaded to a registry, it needs to be built locally.

```sh
git clone https://github.com/TruckeeAviator/qBittorrent-Nordvpn.git
cd qBittorrent-Nordvpn
docker build -t qBittorrent-Nordvpn .
```

## Usage

Docker compose or Docker CLI can be used to run the container. Podman seem to not allow the vpn connection at this time.

### docker compose

```yaml
---
services:
  qbittorrent:
    image: qbittorrent-nordvpn:latest
    container_name: qbittorrent-nordvpn
    environment:
      - TZ=America/Los_Angeles
      - NORD_TOKEN=yourtokenhere # Required
      - QT_PASS=qbittorrentadminpassword # Required
    cap_add:
      - NET_ADMIN
    volumes:
      - /path/to/qbittorrent/appdata:/config # Not required or recommended
      - /path/to/downloads:/downloads
    ports:
      - 8080:8080
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
```

### docker cli

```bash
docker run -d \
  --name=qbittorrent-nordvpn \
  -e TZ=America/Los_Angeles \
  -e NORD_TOKEN=yourtokenhere
  -e QT_PASS=qbittorrentadminpassword \
  -p 8080:8080 \
  -p 6881:6881 \
  -p 6881:6881/udp \
  -v /path/to/qbittorrent/appdata:/config \
  -v /path/to/downloads:/downloads \
  --cap-add=NET_ADMIN \
  --restart unless-stopped \
  qbittorrent-nordvpn:latest
```

## Issues

Sometimes the connection to the VPN is not made at a container start. This has mostly been solved by adding a timer before starting the daemon. You can confirm the connection by issuing ```docker logs qBittorrent-Nordvpn```. Look for similar output:
```
Connecting to United States #9679 (us9679.nordvpn.com)
You are connected to United States #9679 (us9679.nordvpn.com)!
```

### Credit

1. Idea and part of the Dockerfile credit goes to [DyonR](https://github.com/DyonR/docker-qbittorrentvpn)
2. Hash generation script was from the user *57d6f0* in the [qBittorrent forums](https://forum.qbittorrent.org/viewtopic.php?t=8149)
3. [qBittorrent](https://github.com/qbittorrent/qBittorrent)