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

# Install required dependencies
RUN apt update && apt install -y \
    nmap \
    curl \
    wget \
    netcat \
    eyewitness \
    xrdp \
    && apt clean

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
