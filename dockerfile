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

# Set default keyboard layout to UK to bypass interactive prompt
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "keyboard-configuration keyboard-configuration/layout select United Kingdom" | debconf-set-selections && \
    echo "keyboard-configuration keyboard-configuration/model select Generic 105-key PC (intl.)" | debconf-set-selections && \
    echo "keyboard-configuration keyboard-configuration/layoutcode string gb" | debconf-set-selections && \
    echo "keyboard-configuration keyboard-configuration/variant select English (UK)" | debconf-set-selections

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-dev \
    xvfb \
    cmake \
    firefox-esr \
    xrdp \
    nmap \
    curl \
    wget \
    netcat \
    locales \
    keyboard-configuration \
    && apt-get clean

# Set UK locale
RUN echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_GB.UTF-8

# Clone EyeWitness repository
RUN git clone https://github.com/RedSiege/EyeWitness.git /opt/EyeWitness

# Run EyeWitness setup without user input
RUN cd /opt/EyeWitness/Python/setup && \
    chmod +x setup.sh && \
    ./setup.sh << EOF
    1 # Select "English (UK)" keyboard layout
EOF

# Add EyeWitness to PATH
ENV PATH="/opt/EyeWitness/Python:${PATH}"

# Copy scan script
COPY scan.sh /app/scan.sh

# Make script executable
RUN chmod +x /app/scan.sh

# Set environment variable with a default (override at runtime)
ENV TARGET_IP=127.0.0.1

# Set the entrypoint
ENTRYPOINT ["/app/scan.sh"]
