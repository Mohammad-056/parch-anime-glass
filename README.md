# 🌌 Parch Anime Glass Theme (KDE Plasma 6 + Seamless Boot)

A complete, automated Anime & Emerald Glass customization suite for Parch Linux (and Arch-based distributions) running KDE Plasma 6. This project goes beyond simple dotfiles by integrating a seamless visual transition from BIOS/GRUB to Plymouth, Login Manager, Lockscreen, and the KDE Desktop.

---

## ✨ Key Technical Features

* Seamless Boot Pipeline (GRUB ➔ Handoff ➔ Plymouth):
  * Custom anime-glass GRUB theme with dynamic resolution framebuffer handoff (41_handoff) and suppressed kernel loading echo (grub-noloading).
  * Mathematical ffmpeg-rendered Plymouth splash animation with smooth pulsing cursor.
* Binary-Patched Plasma Login Manager & Pacman Hooks:
  * Automated binary patch (patch-login-greeter.sh) removing unwanted default blur layers on custom glass login cards.
  * Persistent systemd path watchers and pacman post-transaction hooks (login-greeter-noblur.hook) ensuring updates never break the theme.
* Automated AUR Plugin Rebuild System:
  * Background pacman hooks and user systemd services to flag and rebuild kwin-effects-better-blur-dx and klassy after KDE/Qt upgrades.
* Custom KDE Plasma 6 Glass & QML Tweaks:
  * Custom translucent plasma panel (MyGlass), KWin window opacity rules, and custom QML lockscreen fader (MyFader.qml).
  * Animated desktop video wallpaper integration (Smart Video Wallpaper Reborn).
  * Custom Konsole (ParchGlass.colorscheme) and Fastfetch anime sixel configuration.

---

## 🚀 One-Line Installation (نصب سریع با یک دستور)

Open your terminal in Parch Linux / Arch Linux (KDE Plasma 6) and run:

`bash
git clone https://github.com/mohammad-dev-linux/parch-anime-glass.git && cd parch-anime-glass && ./install.sh
`

---

## 📂 Project Structure

`text
parch-anime-glass/
├── configs/        # KDE Plasma (MyGlass), KWin rules, Konsole & Fastfetch configs
├── grub/           # anime-glass GRUB theme, 41_handoff & grub-noloading scripts
├── kde-rebuild/    # Pacman hooks & systemd units for automatic KWin plugin rebuilds
├── lockscreen/     # Custom LockScreenUi.qml & MyFader.qml modifications
├── login/          # Plasma Login Manager binary patcher, systemd units & hooks
├── plymouth/       # anime-glass & parch-terminal boot splash themes
├── wallpapers/     # Login background & animated desktop video wallpaper
└── install.sh      # Automated one-click installer script
`

---

## 🇮🇷 راهنمای فارسی

پروژه Parch Anime Glass یک پکیج کامل و خودکار برای شخصی‌سازی عمیق لینوکس پارچ (Parch Linux) و توزیع‌های مبتنی بر آرچ با میزکار KDE Plasma 6 است.

### ویژگی‌های اصلی:
1. بوت یکپارچه و بدون پرش تصویر: تم اختصاصی GRUB به همراه اسکریپت Handoff و انیمیشن بوت Plymouth.
2. پچ خودکار صفحه لاگین و قفل صفحه: حذف تاری ناخواسته صفحه لاگین با پچ باینری و حفظ تغییرات پس از آپدیت‌های سیستم با استفاده از Pacman Hooks.
3. پوسته شیشه‌ای میزکار و ترمینال: تنظیمات آماده برای افکت شیشه‌ای پنجره‌ها (Better Blur DX)، پنل شفاف MyGlass، والپیپر ویدیویی متحرک و ظاهر اختصاصی Konsole و Fastfetch.

برای نصب کافی است دستور موجود در بخش One-Line Installation را در ترمینال کپی و اجرا کنید و پس از اتمام، سیستم را ری‌استارت نمایید.

---

## 🤝 Credits & AI-Assisted Development

* Architecture, System Integration & Customization: [Mohammad (@mohammad-dev-linux)](https://github.com/mohammad-dev-linux)
* AI-Assisted Engineering: Developed using modern AI-assisted workflows for complex ffmpeg filtergraph generation, systemd automation units, binary patching scripts, and repository packaging.

## 📄 License

Licensed under the [MIT License](LICENSE).

---

## 🔄 Uninstall & Rollback (بازگردانی سیستم به حالت قبلی)

Before applying changes, install.sh automatically backs up your previous configurations inside ~/.parch-anime-glass-backup. If you ever wish to revert your system back to its original state, simply run:

`bash
cd ~/parch-anime-glass && ./uninstall.sh
`
