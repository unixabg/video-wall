#!/bin/bash

set -e

# --- Parse arguments ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --hostname) HOSTNAME_PARAM="$2"; shift ;;
    --server-ip) SERVER_IP="$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# --- Validate required arguments ---
if [[ -z "$HOSTNAME_PARAM" || -z "$SERVER_IP" ]]; then
  echo "❌ ERROR: Both --hostname and --server-ip are required."
  echo "Usage: vw-kiosk-install.sh --hostname 0-1 --server-ip 192.168.20.10"
  exit 1
fi

if ! [[ "$HOSTNAME_PARAM" =~ ^[0-9]+-[0-9]+$ ]]; then
  echo "❌ ERROR: Hostname must be in the format row-col (e.g. 0-1)"
  exit 1
fi

echo "✅ Setting hostname to $HOSTNAME_PARAM"
hostnamectl set-hostname "$HOSTNAME_PARAM"

# --- Install necessary packages ---
echo ">>> Installing packages..."
apt update
apt upgrade -f -y
apt install -y chromium lightdm metacity

# --- Add kiosk user ---
echo ">>> Creating kiosk user"
adduser --quiet --disabled-password --shell /bin/bash --home /home/kiosk --gecos "User" kiosk
echo "kiosk:kiosk_password" | chpasswd

# --- Create kiosk launch script ---
echo ">>> Writing /usr/bin/kiosk"
cat > /usr/bin/kiosk << EOF
#!/bin/bash
setterm -blank 0 -powersave off -powerdown 0
xset -dpms
xset s off
xset s noblank

# Clear Chromium cache and config
echo "Just for sanity let's drop the .cache and .config for kiosk."
rm -rf /home/kiosk/.cache/chromium
rm -rf /home/kiosk/.config/chromium
rm -f /var/cache/lightdm/dmrc/kiosk.dmrc

/usr/bin/metacity &

HOSTNAME=\$(hostname)
/usr/bin/chromium --kiosk --noerrdialogs --disable-infobars --autoplay-policy=no-user-gesture-required "http://$SERVER_IP:8080/?hostname=\$HOSTNAME"
EOF

chmod +x /usr/bin/kiosk

# --- LightDM session entry ---
echo ">>> Writing kiosk.desktop"
cat > /usr/share/xsessions/kiosk.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Name=Kiosk
Comment=This session logs you into a chromium kiosk session.
Exec=/usr/bin/kiosk
Icon=
Type=Application
EOF

# --- Enable autologin in LightDM ---
echo ">>> Configuring LightDM"
cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak
sed -i 's/#autologin-user=/autologin-user=kiosk/' /etc/lightdm/lightdm.conf
sed -i 's/#autologin-session=/autologin-session=kiosk/' /etc/lightdm/lightdm.conf

echo "✅ Kiosk installation complete. Reboot to test."

