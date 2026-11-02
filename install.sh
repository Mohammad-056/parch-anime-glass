#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a normal user (not root). It will ask for sudo when needed."
    exit 1
fi

echo "===================================================="
echo "     Installing Parch Anime Glass Theme (KDE 6)     "
BACKUP_DIR="$HOME/.parch-anime-glass-backup"

if [ ! -d "$BACKUP_DIR" ]; then

    echo "[*] Creating backup of your current configs in $BACKUP_DIR..."

    mkdir -p "$BACKUP_DIR/configs"

    sudo cp /etc/default/grub "$BACKUP_DIR/grub.bak" 2>/dev/null || true

    plymouth-set-default-theme > "$BACKUP_DIR/plymouth_theme.txt" 2>/dev/null || true

    for f in kwinrc kwinrulesrc kdeglobals plasmarc plasma-org.kde.plasma.desktop-appletsrc kscreenlockerrc; do

        [ -f "$HOME/.config/$f" ] && cp "$HOME/.config/$f" "$BACKUP_DIR/configs/"

    done

    [ -f "$HOME/.config/fastfetch/config.jsonc" ] && cp "$HOME/.config/fastfetch/config.jsonc" "$BACKUP_DIR/configs/"

fi
echo "===================================================="

# 1. نصب پیش‌نیازهای رسمی
echo "[*] Installing official dependencies..."
sudo pacman -S --needed --noconfirm grub plymouth ffmpeg imagemagick fastfetch konsole libnotify perl gzip

# 2. نصب پکیج‌های AUR (Klassy & Better Blur DX & Video Wallpaper)
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

if [ -n "$AUR_HELPER" ]; then
    echo "[*] Installing AUR packages using $AUR_HELPER..."
    $AUR_HELPER -S --needed --noconfirm klassy kwin-effects-better-blur-dx plasma6-wallpapers-smart-video-wallpaper-reborn
else
    echo "[!] Warning: Neither paru nor yay found. Skipping AUR packages."
fi

# 3. نصب تم GRUB و Handoff
echo "[*] Configuring Anime Glass GRUB theme & seamless handoff..."
sudo mkdir -p /boot/grub/themes/
sudo cp -r ./grub/anime-glass /boot/grub/themes/
if [ -f "./grub/41_handoff" ]; then
    sudo cp ./grub/41_handoff /etc/grub.d/41_handoff
    sudo chmod +x /etc/grub.d/41_handoff
fi
if [ -f "./grub/grub-noloading" ]; then
    sudo cp ./grub/grub-noloading /usr/local/bin/grub-noloading
    sudo chmod +x /usr/local/bin/grub-noloading
fi

sudo sed -i '/^#\?GRUB_THEME=/d' /etc/default/grub
sudo sed -i '/^#\?GRUB_GFXPAYLOAD_LINUX=/d' /etc/default/grub
echo 'GRUB_THEME="/boot/grub/themes/anime-glass/theme.txt"' | sudo tee -a /etc/default/grub >/dev/null
echo 'GRUB_GFXPAYLOAD_LINUX=keep' | sudo tee -a /etc/default/grub >/dev/null

# 4. نصب تم Plymouth
echo "[*] Configuring Plymouth boot splash..."
sudo cp -r ./plymouth/anime-glass /usr/share/plymouth/themes/ 2>/dev/null || true
sudo cp -r ./plymouth/parch-terminal /usr/share/plymouth/themes/ 2>/dev/null || trueif [ -f "/sys/class/graphics/fb0/virtual_size" ] && [ -d "/usr/share/plymouth/themes/anime-glass" ]; then
    P=/usr/share/plymouth/themes/anime-glass
    read W H < <(tr ',' ' ' < /sys/class/graphics/fb0/virtual_size)
    X=$(((W-640)/2)); Y=$(((H-200)/2))
    sudo ffmpeg -y -loglevel error -f lavfi -i color=c=black:s=${W}x${H} -i $P/box.png -i $P/cur.png -filter_complex "[0:v]format=rgb24[bg];[2:v]format=rgba,colorchannelmixer=aa=0.57[c];[bg][1:v]overlay=${X}:${Y}:format=rgb[t];[t][c]overlay=${X}:${Y}:format=rgb,format=rgb24" -frames:v 1 -update 1 /boot/grub/themes/anime-glass/handoff.png || true
fi

sudo plymouth-set-default-theme -R anime-glass
sudo grub-mkconfig -o /boot/grub/grub.cfg
[ -x "/usr/local/bin/grub-noloading" ] && sudo /usr/local/bin/grub-noloading

# 5. نصب پچ صفحه لاگین و والپیپر
echo "[*] Applying Plasma Login Manager glass patch..."
sudo mkdir -p /var/lib/plasmalogin/wallpapers /etc/pacman.d/hooks
if [ -f "./wallpapers/login_background.jpg" ]; then
    sudo cp ./wallpapers/login_background.jpg /var/lib/plasmalogin/wallpapers/login_background.jpg
fi
[ -f "./login/plasmalogin.conf" ] && sudo cp ./login/plasmalogin.conf /etc/
[ -f "./login/plasmalogin-glass.list" ] && sudo cp ./login/plasmalogin-glass.list /etc/
if [ -f "./login/patch-login-greeter.sh" ]; then
    sudo cp ./login/patch-login-greeter.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/patch-login-greeter.sh
    sudo /usr/local/bin/patch-login-greeter.sh || true
fi
[ -f "./login/login-greeter-noblur.hook" ] && sudo cp ./login/login-greeter-noblur.hook /etc/pacman.d/hooks/
sudo cp ./login/login-greeter-mode.* /etc/systemd/system/ 2>/dev/null || true
sudo systemctl daemon-reload
sudo systemctl enable --now login-greeter-mode.path 2>/dev/null || true

# 6. نصب سرویس بازبیلد خودکار پلاگین‌های KDE
if [ -d "./kde-rebuild" ]; then
    echo "[*] Setting up automatic KDE plugin rebuild hooks..."
    sudo cp ./kde-rebuild/kde-plugin-flag.sh ./kde-rebuild/rebuild-kde-plugins /usr/local/bin/ 2>/dev/null || true
    sudo chmod +x /usr/local/bin/kde-plugin-flag.sh /usr/local/bin/rebuild-kde-plugins 2>/dev/null || true
    sudo cp ./kde-rebuild/kde-plugin-rebuild.hook /etc/pacman.d/hooks/ 2>/dev/null || true
    mkdir -p ~/.config/systemd/user
    cp ./kde-rebuild/kde-plugin-check.* ~/.config/systemd/user/ 2>/dev/null || true
    systemctl --user daemon-reload || true
    systemctl --user enable --now kde-plugin-check.path 2>/dev/null || true
fi

# 7. نصب تغییرات QML قفل صفحه
echo "[*] Configuring Lockscreen QML..."
LOCK_DIR="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen"
if [ -d "$LOCK_DIR" ] && [ -f "./lockscreen/MyFader.qml" ]; then
    sudo cp ./lockscreen/MyFader.qml "$LOCK_DIR/"
    sudo cp ./lockscreen/LockScreenUi.qml "$LOCK_DIR/"
fi
if [ -f "./lockscreen/kscreenlockerrc" ]; then
    sed "s|/home/mohammad/Downloads/login_background.jpg|/var/lib/plasmalogin/wallpapers/login_background.jpg|g; s|/home/mohammad|$HOME|g" ./lockscreen/kscreenlockerrc > ~/.config/kscreenlockerrc
fi

# 8. نصب کانفیگ‌های KDE Plasma، ترمینال و Fastfetch
echo "[*] Applying KDE Plasma Glass configs, Konsole & Fastfetch..."
mkdir -p ~/.local/share/plasma/desktoptheme ~/.local/share/konsole ~/.config/fastfetch ~/.local/share/wallpapers
[ -f "./wallpapers/desktop_video.mp4" ] && cp ./wallpapers/desktop_video.mp4 ~/.local/share/wallpapers/
cp -r ./configs/plasma/MyGlass ~/.local/share/plasma/desktoptheme/ 2>/dev/null || true
cp ./configs/konsole/* ~/.local/share/konsole/ 2>/dev/null || true
cp ./configs/fastfetch/* ~/.config/fastfetch/ 2>/dev/null || true
[ -f ~/.config/fastfetch/config.jsonc ] && sed -i "s|/home/mohammad|$HOME|g" ~/.config/fastfetch/config.jsonc

for cfg in kwinrc kwinrulesrc kdeglobals plasmarc plasma-org.kde.plasma.desktop-appletsrc; do
    if [ -f "./configs/kwin/$cfg" ]; then
        sed "s|/home/mohammad|$HOME|g" "./configs/kwin/$cfg" > ~/.config/$cfg
    fi
done

plasma-apply-desktoptheme MyGlass 2>/dev/null || trueecho "===================================================="
echo " [+] Installation Complete! Please reboot your PC.  "
echo "===================================================="
