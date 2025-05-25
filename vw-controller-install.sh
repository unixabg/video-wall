#!/bin/bash

set -e

# --- Parse args ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --rows) rows="$2"; shift ;;
    --cols) cols="$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# --- Check required flags ---
if [[ -z "$rows" || -z "$cols" ]]; then
  echo "Usage: vw-controller-install --rows <number> --cols <number>"
  exit 1
fi

echo ">>> Installing video wall controller with layout ${rows}x${cols}"

# --- Set hostname to 0-0-R-C ---
hostname="0-0-${rows}-${cols}"
echo ">>> Setting hostname to ${hostname}"
hostnamectl set-hostname "$hostname"

# --- Install dependencies ---
echo ">>> Installing required packages..."
apt update
apt install -y git python3 python3-pip python3-websockets

# --- Clone the project ---
echo ">>> Cloning GitHub repo..."
cd /opt
rm -rf video-wall  # clean reinstall
git clone https://github.com/unixabg/video-wall.git
cd video-wall

# --- Create systemd service ---
echo ">>> Creating systemd service to auto-launch server.py"
cat > /etc/systemd/system/vw-server.service <<EOF
[Unit]
Description=Video Wall Controller - server.py
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/video-wall/server.py
WorkingDirectory=/opt/video-wall
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vw-server.service
systemctl start vw-server.service

echo "✅ Done! Hostname set to ${hostname}, server.py running on boot."
