#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a normal user (not root). It will ask for sudo when needed."
    exit 1
fi

echo "===================================================="
echo "   Uninstalling Parch Anime Glass Theme & Restoring "
echo "===================================================="

BACKUP_DIR="$HOME/.parch-anime-glass-backup"

# 1. بازگردانی پچ باینری صفحه لاگین و حذف سرویس‌ها
echo "[*] Reverting Plasma Login Manager binary patch & hooks..."
if [ -f "/usr/lib/plasma-login-greeter" ]; then
    sudo perl -pi -e 's/NoBlurScreenBrdg/BlurScreenBridge/g' /usr/lib/plasma-login-greeter || true
fi
sudo systemctl disable --now login-greeter-mode.path login-greeter-mode.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/login-greeter-mode.* /etc/pacman.d/hooks/login-greeter-noblur.hook /usr/local/bin/patch-login-greeter.sh /etc/plasmalogin-glass.list

# 2. حذف سرویس بازبیلد خودکار پلاگین‌های KDE
echo "[*] Removing automatic KDE plugin rebuild hooks..."
systemctl --user disable --now kde-plugin-check.path kde-plugin-check.service 2>/dev/null || true
rm -f ~/.config/systemd/user/kde-plugin-check.*
sudo rm -f /etc/pacman.d/hooks/kde-plugin-rebuild.hook /usr/local/bin/kde-plugin-flag.sh /usr/local/bin/rebuild-kde-plugins
sudo systemctl daemon-reload
systemctl --user daemon-reload || true

# 3. بازگردانی قفل صفحه (Lockscreen QML) به حالت استاندارد
echo "[*] Restoring default Lockscreen QML..."
LOCK_DIR="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen"
if [ -f "$LOCK_DIR/LockScreenUi.qml" ]; then
    sudo sed -i 's/^\(\s*\)MyFader {/\1WallpaperFader {/' "$LOCK_DIR/LockScreenUi.qml" || true
    sudo rm -f "$LOCK_DIR/MyFader.qml"
fi

# 4. بازگردانی GRUB و Plymouth به حالت قبل
echo "[*] Restoring previous GRUB and Plymouth settings..."
sudo rm -f /etc/grub.d/41_handoff /usr/local/bin/grub-noloading
sudo rm -rf /boot/grub/themes/anime-glass /usr/share/plymouth/themes/anime-glass

if [ -f "$BACKUP_DIR/grub.bak" ]; then
    sudo cp "$BACKUP_DIR/grub.bak" /etc/default/grub
else
    sudo sed -i 's|^GRUB_THEME="/boot/grub/themes/anime-glass/theme.txt"|#GRUB_THEME=""|g' /etc/default/grub
fi

if [ -f "$BACKUP_DIR/plymouth_theme.txt" ]; then
    OLD_PLYMOUTH=$(cat "$BACKUP_DIR/plymouth_theme.txt")
    sudo plymouth-set-default-theme -R "$OLD_PLYMOUTH" 2>/dev/null  sudo plymouth-set-default-theme -R bgrt 2>/dev/null  true
else
    sudo plymouth-set-default-theme -R bgrt 2>/dev/null || true
fi
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 5. بازگردانی تنظیمات میزکار KDE Plasma از پوشه بکاپ
echo "[*] Restoring previous KDE Plasma & terminal configurations..."
if [ -d "$BACKUP_DIR/configs" ]; then
    for f in kwinrc kwinrulesrc kdeglobals plasmarc plasma-org.kde.plasma.desktop-appletsrc kscreenlockerrc; do[ -f "$BACKUP_DIR/configs/$f" ] && cp "$BACKUP_DIR/configs/$f" "$HOME/.config/$f"
    done
    [ -f "$BACKUP_DIR/configs/config.jsonc" ] && cp "$BACKUP_DIR/configs/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
else
    rm -f "$HOME/.config/kwinrulesrc"
    plasma-apply-desktoptheme default 2>/dev/null || true
fi

rm -rf "$HOME/.local/share/plasma/desktoptheme/MyGlass"

echo "===================================================="
echo " [+] Uninstall Complete! System restored to previous"
echo "     state. Please reboot your PC.                  "
echo "===================================================="
