#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  dbus-x11 \
  fonts-noto-color-emoji \
  fonts-noto-core \
  fonts-thai-tlwg \
  locales \
  mousepad \
  novnc \
  openssl \
  procps \
  psmisc \
  thunar \
  websockify \
  x11-utils \
  x11-xserver-utils \
  x11vnc \
  xfce4 \
  xfce4-terminal \
  xterm \
  xvfb

sudo locale-gen en_US.UTF-8 th_TH.UTF-8
sudo install -m 0644 \
  .devcontainer/novnc-index.html \
  /usr/share/novnc/index.html

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Ubuntu Desktop packages installed."
