FROM ubuntu:22.04

LABEL maintainer="LinuxEclipsed"

WORKDIR /opt

RUN usermod -u 99 nobody

RUN mkdir -p /downloads /config/qBittorrent /etc/qbittorrent

# Environment settings
ENV HOME="/config" \
XDG_CONFIG_HOME="/config" \
XDG_DATA_HOME="/config"

# Install build packages
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    python3 \
    jq \
    libssl-dev \
    pkg-config \
    qtbase5-dev \
    qttools5-dev \
    zlib1g-dev \
    g++ \
    cmake \
    automake \
    libtool \
    libssl-dev \
    libgeoip-dev \
    libboost-dev \
    libboost-system-dev \
    libboost-chrono-dev \
    libboost-random-dev \
    qtbase5-private-dev \
    libqt5svg5-dev

# Install Libtorrent
RUN LIBTORRENT_ASSETS=$(curl -sX GET "https://api.github.com/repos/arvidn/libtorrent/releases" | jq '.[] | select(.prerelease==false) | select(.target_commitish=="RC_1_2") | .assets_url' | head -n 1 | tr -d '"') \
    && LIBTORRENT_DOWNLOAD_URL=$(curl -sX GET ${LIBTORRENT_ASSETS} | jq '.[0] .browser_download_url' | tr -d '"') \
    && LIBTORRENT_NAME=$(curl -sX GET ${LIBTORRENT_ASSETS} | jq '.[0] .name' | tr -d '"') \
    && curl -o /opt/${LIBTORRENT_NAME} -L ${LIBTORRENT_DOWNLOAD_URL} \
    && tar -xzf /opt/${LIBTORRENT_NAME} \
    && rm /opt/${LIBTORRENT_NAME} \
    && cd /opt/libtorrent-rasterbar* \
    && cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build

# Install qBittorrent
RUN apt install -y --no-install-recommends \
    && QBITTORRENT_RELEASE=$(curl -sX GET "https://api.github.com/repos/qBittorrent/qBittorrent/tags" | jq '.[] | select(.name | index ("alpha") | not) | select(.name | index ("beta") | not) | select(.name | index ("rc") | not) | .name' | head -n 1 | tr -d '"') \
    && curl -o /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz -L "https://github.com/qbittorrent/qBittorrent/archive/${QBITTORRENT_RELEASE}.tar.gz" \
    && tar -xzf /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz \
    && rm /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz \
    && cd /opt/qBittorrent-${QBITTORRENT_RELEASE} \
    && cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DGUI=OFF -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build 

# Install Nord
COPY src/install.sh /opt
RUN chmod +x install.sh && ./install.sh

# Cleanup
RUN cd /opt \
    && rm -rf /opt/* \
    && apt purge -y \
    build-essential \
    curl \
    jq \
    libssl-dev \
    cmake \
    automake \
    libgeoip-dev \
    libboost-dev \
    libboost-system-dev \
    libboost-chrono-dev \
    libboost-random-dev \
    qtbase5-private-dev \
    libqt5svg5-dev \
    && apt-get clean \
    && apt --purge autoremove -y  \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/include/*

COPY src/start.py /
COPY src/qBittorrent.conf /config/qBittorrent

VOLUME /config /downloads

EXPOSE 8080 6881 6881/udp

CMD ["python3", "/start.py"]