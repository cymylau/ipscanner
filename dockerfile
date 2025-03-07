# Use a minimal Debian-based image
FROM debian:bullseye-slim

# Labels
LABEL org.opencontainers.image.title="IP Scanner & Evidence Collector"
LABEL org.opencontainers.image.description="A container that scans a given IP for open ports and collects evidence for well-known services."
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.authors="cymylau"
LABEL org.opencontainers.image.vendor="cymylau"
LABEL org.opencontainers.image.licenses="beer"
LABEL org.opencontainers.image.url="https://github.com/cymylau/ipscanner"
LABEL org.opencontainers.image.documentation="https://github.com/cymylau/ipscanner/readme.md"
LABEL org.opencontainers.image.source="https://github.com/cymylau/ipscanner/dockerfile"

# Set environment to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV UDEV=off

# Prevent udev from running inside the container
RUN echo '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Install required dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap \
    curl \
    wget \
    netcat \
    xrdp \
    python3 \
    python3-pip \
    locales \
    keyboard-configuration \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set UK locale and keyboard layout
RUN echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_GB.UTF-8

# Set working directory
WORKDIR /app

# Copy scan script
COPY scan.sh /app/scan.sh

# Make script executable
RUN chmod +x /app/scan.sh

# Set environment variable with a default (override at runtime)
ENV TARGET_IP=127.0.0.1

# Define the entrypoint
ENTRYPOINT ["/app/scan.sh"]
