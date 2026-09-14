#!/bin/bash
#
# stos-motd.sh
# Message of the day for stos.top
#
# Install as a login banner one of two ways:
#
#   1) Drop into update-motd.d (Debian/OMV style, runs on every SSH login)
#      sudo cp stos-motd.sh /etc/update-motd.d/99-stos
#      sudo chmod +x /etc/update-motd.d/99-stos
#      sudo chmod -x /etc/update-motd.d/10-uname  (optional, kills the default banner)
#
#   2) Or just source it from ~/.bashrc
#      echo "bash /home/youruser/stos-motd.sh" >> ~/.bashrc

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BLUE=$'\033[1;34m'
MAGENTA=$'\033[0;35m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

shopt -s extglob

# force a UTF-8-aware locale for this shell so multi-byte block characters
# below are sliced as single characters, not raw bytes
export LC_ALL=C.UTF-8

# strips ANSI colour codes to get the true printable width of a line,
# needed so the two-column layout below lines up regardless of colour
visible_len() {
  local s="$1"
  local esc=$'\033'
  local stripped="${s//$esc\[+([0-9;])m/}"
  echo "${#stripped}"
}

LEFT_WIDTH=42

# prints one row of the two-column layout, padding the left side out to
# LEFT_WIDTH based on its real (colour-stripped) width
print_row() {
  local l="$1" r="$2"
  local vlen pad
  vlen=$(visible_len "$l")
  pad=$(( LEFT_WIDTH - vlen ))
  [ $pad -lt 1 ] && pad=1
  printf '%s%*s%s\n' "$l" "$pad" "" "$r"
}

ART=(
'▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌'
'▐  ██████ ▄▄▄█████▓ ▒█████    ██████      ▄▄▄█████▓ ▒█████   ██▓███  ▌'
'▐▒██    ▒ ▓  ██▒ ▓▒▒██▒  ██▒▒██    ▒      ▓  ██▒ ▓▒▒██▒  ██▒▓██░  ██▒▌'
'▐░ ▓██▄   ▒ ▓██░ ▒░▒██░  ██▒░ ▓██▄        ▒ ▓██░ ▒░▒██░  ██▒▓██░ ██▓▒▌'
'▐  ▒   ██▒░ ▓██▓ ░ ▒██   ██░  ▒   ██▒     ░ ▓██▓ ░ ▒██   ██░▒██▄█▓▒ ▒▌'
'▐▒██████▒▒  ▒██▒ ░ ░ ████▓▒░▒██████▒▒ ██▓   ▒██▒ ░ ░ ████▓▒░▒██▒ ░  ░▌'
'▐▒ ▒▓▒ ▒ ░  ▒ ░░   ░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░ ▒▓▒   ▒ ░░   ░ ▒░▒░▒░ ▒▓▒░ ░  ░▌'
'▐░ ░▒  ░ ░    ░      ░ ▒ ▒░ ░ ░▒  ░ ░ ░▒      ░      ░ ▒ ▒░ ░▒ ░     ▌'
'▐░  ░  ░    ░      ░ ░ ░ ▒  ░  ░  ░   ░     ░      ░ ░ ░ ▒  ░░       ▌'
'▐      ░               ░ ░        ░    ░               ░ ░           ▌'
'▐                                      ░                             ▌'
'▐▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌'
)

# vertical red-to-orange gradient top to bottom, outer frame held solid yellow
# 24-bit colour, falls back oddly only on very old terminals without truecolour
echo ""
TOTAL=${#ART[@]}
LASTROW=$((TOTAL-1))
for (( r=0; r<TOTAL; r++ )); do
  LINE="${ART[r]}"
  LEN=${#LINE}
  if [ $r -eq 0 ] || [ $r -eq $LASTROW ]; then
    printf "\033[1m\033[38;2;255;255;0m%s${NC}\n" "$LINE"
    continue
  fi
  CROWS=$((TOTAL-2))
  ROWIDX=$((r-1))
  G=$(( ROWIDX * 165 / (CROWS-1) ))
  for (( i=0; i<LEN; i++ )); do
    CH="${LINE:i:1}"
    if [ $i -eq 0 ] || [ $i -eq $((LEN-1)) ]; then
      printf "\033[1m\033[38;2;255;255;0m%s" "$CH"
    else
      printf "\033[1m\033[38;2;255;%d;0m%s" "$G" "$CH"
    fi
  done
  printf "${NC}\n"
done

# ---- gather live stats ----
HOST=$(hostname)
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
KERNEL=$(uname -r)
UP=$(uptime -p 2>/dev/null | sed 's/up //')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')
MEM=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}')

# CPU usage, sampled over a short window from /proc/stat
read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ _ < /proc/stat
sleep 0.3
read -r _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ _ < /proc/stat
TOTAL1=$((u1+n1+s1+i1+w1+irq1+sirq1+st1))
TOTAL2=$((u2+n2+s2+i2+w2+irq2+sirq2+st2))
IDLE1=$((i1+w1))
IDLE2=$((i2+w2))
DTOTAL=$((TOTAL2-TOTAL1))
DIDLE=$((IDLE2-IDLE1))
if [ "$DTOTAL" -gt 0 ]; then
  CPU_PCT=$(( 100*(DTOTAL-DIDLE)/DTOTAL ))
else
  CPU_PCT="n/a"
fi

DOCKER_UP=$(docker ps -q 2>/dev/null | wc -l)
DOCKER_ALL=$(docker ps -aq 2>/dev/null | wc -l)
DOCKER_DOWN=$((DOCKER_ALL - DOCKER_UP))

UPDATES=0
if command -v apt >/dev/null 2>&1; then
  UPDATES=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
fi

DATESTR=$(date '+%A %d %B %Y, %H:%M')

SYSTEM_LINE=$(df -h / 2>/dev/null | awk -v y="$YELLOW" -v b="$BOLD" -v n="$NC" 'NR==2 {print "  "y b"System"n"   "$3" / "$2"  ("$5" used)"}')

POOL_NAME=""
if command -v zpool >/dev/null 2>&1; then
  POOL_NAME=$(zpool list -H -o name 2>/dev/null | head -n1)
fi

# ---- build the left column: host stats + disk usage ----
LEFT=()
LEFT+=("${YELLOW}${BOLD}Host${NC}       ${HOST}  (${IP})")
LEFT+=("${YELLOW}${BOLD}Kernel${NC}     ${KERNEL}")
LEFT+=("${YELLOW}${BOLD}Uptime${NC}     ${UP}")
LEFT+=("${YELLOW}${BOLD}CPU${NC}        ${CPU_PCT}%  (load ${LOAD})")
LEFT+=("${YELLOW}${BOLD}Memory${NC}     ${MEM}")

if command -v apt >/dev/null 2>&1; then
  if [ "$UPDATES" -gt 0 ]; then
    LEFT+=("${YELLOW}${BOLD}Updates${NC}    ${RED}${UPDATES} pending${NC}")
  else
    LEFT+=("${YELLOW}${BOLD}Updates${NC}    ${GREEN}up to date${NC}")
  fi
fi

if [ -f /var/run/reboot-required ]; then
  LEFT+=("${RED}${BOLD}Reboot${NC}     required")
fi

LEFT+=("")
LEFT+=("${MAGENTA}${BOLD}Disk usage${NC}")
[ -n "$SYSTEM_LINE" ] && LEFT+=("$SYSTEM_LINE")
LEFT+=("")

if [ -n "$POOL_NAME" ]; then
  read -r PUSED_B PAVAIL_B <<< "$(zfs list -H -p -o used,avail "$POOL_NAME" 2>/dev/null)"
  PTOTAL_B=$((PUSED_B + PAVAIL_B))
  if [ "$PTOTAL_B" -gt 0 ]; then
    PCAP=$(( PUSED_B * 100 / PTOTAL_B ))
  else
    PCAP=0
  fi
  if command -v numfmt >/dev/null 2>&1; then
    PUSED_H=$(numfmt --to=iec --format="%.1f" "$PUSED_B" 2>/dev/null)
    PTOTAL_H=$(numfmt --to=iec --format="%.1f" "$PTOTAL_B" 2>/dev/null)
  else
    PUSED_H="$PUSED_B"
    PTOTAL_H="$PTOTAL_B"
  fi
  LEFT+=("  ${YELLOW}${BOLD}${POOL_NAME}${NC}    ${PUSED_H} / ${PTOTAL_H}  (${PCAP}% used)")
  while read -r DNAME DUSED; do
    LABEL=$(basename "$DNAME")
    LEFT+=("$(printf '    %-11s%s' "$LABEL" "$DUSED")")
  done < <(zfs list -H -o name,used -r "$POOL_NAME" 2>/dev/null | tail -n +2)
else
  # fallback for non-ZFS systems, real mounts grouped under one pool header
  LEFT+=("  ${YELLOW}${BOLD}Pool${NC}")
  while read -r FS SIZE USED AVAIL PCT MOUNT; do
    [ "$MOUNT" = "/" ] && continue
    LABEL=$(basename "$MOUNT")
    LEFT+=("$(printf '    %-11s%s' "$LABEL" "$USED")")
  done < <(df -h -x tmpfs -x devtmpfs -x overlay -x squashfs -x proc -x sysfs -x cgroup -x efivarfs -x vfat 2>/dev/null | tail -n +2)
fi

# ---- build the right column: containers + core services ----
RIGHT=()
if command -v docker >/dev/null 2>&1; then
  if [ "$DOCKER_DOWN" -gt 0 ]; then
    RIGHT+=("${GREEN}${BOLD}Containers${NC}  ${GREEN}${DOCKER_UP} up${NC}, ${RED}${DOCKER_DOWN} down${NC} (of ${DOCKER_ALL})")
  else
    RIGHT+=("${GREEN}${BOLD}Containers${NC}  ${GREEN}${DOCKER_UP} up${NC} (of ${DOCKER_ALL})")
  fi
  RIGHT+=("")
  RIGHT+=("${MAGENTA}${BOLD}Core services${NC}")
  for SVC in jellyfin clipcascade audiobookshelf grimmory komga nginx-proxy-manager cloudflare-ddns; do
    STATE=$(docker ps --filter "name=${SVC}" --format '{{.Status}}' 2>/dev/null | head -n1)
    if [ -n "$STATE" ]; then
      RIGHT+=("  ${GREEN}●${NC} ${SVC}   ${DIM}${STATE}${NC}")
    else
      MATCH=$(docker ps -a --filter "name=${SVC}" --format '{{.Status}}' 2>/dev/null | head -n1)
      if [ -n "$MATCH" ]; then
        RIGHT+=("  ${RED}●${NC} ${SVC}   ${DIM}${MATCH}${NC}")
      fi
    fi
  done
fi

# ---- print both columns side by side ----
ROWS=${#LEFT[@]}
[ ${#RIGHT[@]} -gt $ROWS ] && ROWS=${#RIGHT[@]}
for (( i=0; i<ROWS; i++ )); do
  print_row "${LEFT[i]:-}" "${RIGHT[i]:-}"
done

echo ""

QUOTES=(
  "No backup, no sympathy."
  "Not a homelab until something breaks at 2am."
  "Docker restart: policy unless-stopped, hope: policy always."
  "There are two types of NAS owners, those who've lost data and those who will."
  "Your containers are up. Your standards remain low."
  "RAID is not a backup and this message will repeat until you set one up."
  "Tailscale connected. Family still asking why Netflix isn't free here."
  "systemctl status motivation: failed"
  "This server has seen things your browser history hasn't."
  "99 percent uptime, 1 percent me forgetting why I opened the terminal."
  "Half of self-hosting is fixing what worked yesterday."
  "Your NAS remembers everything you meant to delete."
  "Latency is the universe asking you to wait."
  "Every reboot is a small act of faith."
  "The cloud is someone else's problem, this is yours."
  "Grafana dashboards, proof you have graphs and no answers."
  "Your uptime graph looks better than your sleep schedule."
  "Nothing says stability like three unlabeled cron jobs."
  "Someone else's server never smells like burning fan bearings."
  "A watched docker pull never finishes."
)
PICK=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
echo -e "${BLUE}${PICK}${NC}"
echo -e "${DIM}${DATESTR}${NC}"
echo ""
