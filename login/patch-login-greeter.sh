#!/bin/sh
LIST=/etc/plasmalogin-glass.list   # name = force glass, !name = force normal
STATE=/var/lib/login-greeter
LOG=/var/log/login-greeter-patch.log
PAT='BlurScreenBridge|NoBlurScreenBrdg'
log() { echo "$(date '+%F %T') $1" >> "$LOG"; echo "login-greeter: $1"; }

mkdir -p "$STATE"
exec 9>"$STATE/lock"
flock -w 30 9 || exit 0

# 1) find the greeter binary
F=""
for c in /usr/lib/plasma-login-greeter /usr/libexec/plasma-login-greeter /usr/lib/plasmalogin/plasma-login-greeter; do
  [ -f "$c" ] && grep -aqE "$PAT" "$c" && F=$c && break
done
if [ -z "$F" ]; then
  F=$(find /usr/lib /usr/libexec -maxdepth 3 -type f -name '*greeter*' 2>/dev/null |
      while read -r f; do grep -aqE "$PAT" "$f" 2>/dev/null && echo "$f" && break; done)
fi
if [ -z "$F" ]; then
  log "WARNING: greeter not found or blur class renamed, patch must be updated"
  exit 0
fi

# 2) current login image
img=$(cat /etc/plasmalogin.conf /etc/plasmalogin.conf.d/*.conf /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null |
      sed -n 's/^[[:space:]]*Image=//p' | tail -1)
name=$(basename "${img#file://}")

# 3) decide
want=blur; why="no image set"
if [ -n "$name" ]; then
  if [ -f "$LIST" ] && grep -qxF "!$name" "$LIST"; then want=blur; why="forced normal ($name)"
  elif [ -f "$LIST" ] && grep -qxF "$name" "$LIST"; then want=noblur; why="in list ($name)"
  elif echo "$name" | grep -qi glass; then want=noblur; why="glass in name ($name)"
  else want=blur; why="normal ($name)"; fi
fi

# 4) safe apply: patch a copy, verify size, then replace
apply() {  # $1=from $2=to
  tmp=$(mktemp "$F.XXXXXX") || return 1
  cp -p "$F" "$tmp" && perl -pi -e "s/$1/$2/g" "$tmp"
  if [ "$(stat -c %s "$tmp")" = "$(stat -c %s "$F")" ] && grep -aq "$2" "$tmp"; then
    mv -f "$tmp" "$F"
  else
    rm -f "$tmp"; log "ERROR: patch verification failed, file untouched"; return 1
  fi
}

if [ "$want" = noblur ]; then
  if grep -aq "BlurScreenBridge" "$F"; then apply BlurScreenBridge NoBlurScreenBrdg && log "blur removed: $why"
  else echo "login-greeter: already no blur: $why"; fi
else
  if grep -aq "NoBlurScreenBrdg" "$F"; then apply NoBlurScreenBrdg BlurScreenBridge && log "blur restored: $why"
  else echo "login-greeter: default blur: $why"; fi
fi
exit 0
