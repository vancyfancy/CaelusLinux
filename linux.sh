#!/bin/bash

GITHUB_REPO="caelusinfra/game-launcher"
INSTALL_DIR="$HOME/.local/share/aisaka"
DESKTOP_APPS="$HOME/.local/share/applications"
ENTRY_FILE="$DESKTOP_APPS/aisaka-player.desktop"
UNINSTALL_ENTRY_FILE="$DESKTOP_APPS/aisaka-player-uninstall.desktop"

echo "CaelusLinux b0.1"
echo ""

if [[ "${1:-}" == "--uri" ]]; then
    uri_cleaned="${2/aisaka-player:\/\//}"
    uri_cleaned="${uri_cleaned/aisaka-player:/}"
    year="2017L"
    args=()
    while IFS= read -r param; do
        [[ "$param" != *":"* ]] && continue
        key="${param%%:*}"
        val="${param#*:}"
        [[ -z "$val" ]] && continue
        case "$key" in
            clientversion)    year="$val" ;;
            launchmode)       args+=("-$val" "-a" "https://www.caelus.lol/Login/Negotiate.ashx") ;;
            placelauncherurl) args+=("--placelauncherUrl" "$(python3 -c "import urllib.parse,sys; print(urllib.parse.unquote(sys.argv[1]))" "$val")") ;;
            gameinfo)         args+=("--gameInfo" "$val") ;;
            robloxLocale)     args+=("--rloc" "$val") ;;
            gameLocale)       args+=("--gloc" "$val") ;;
        esac
    done < <(tr '+' '\n' <<< "$uri_cleaned")
    exe="$INSTALL_DIR/AisakaLauncher.exe"
    [[ ! -f "$exe" ]] && exit 1
    wine_cmd=""
    for w in wine64 wine; do
        command -v "$w" &>/dev/null && { wine_cmd="$w"; break; }
    done
    [[ -z "$wine_cmd" ]] && exit 1
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    setsid "$wine_cmd" "$exe" "${args[@]}" </dev/null &>/dev/null &
    exit 0
fi

if [[ "${1:-}" == "--uninstall" ]]; then
    rm -f "$ENTRY_FILE" "$UNINSTALL_ENTRY_FILE"
    update-desktop-database "$DESKTOP_APPS" &>/dev/null || true
    exit 0
fi

echo "[*] Downloading Aisaka..."

mkdir -p "$INSTALL_DIR" || { echo "[!] Aisaka encountered an error, please DM vancyfancy on Discord."; exit 1; }

LATEST_URL=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
    | grep "browser_download_url" \
    | grep -i "\.exe" \
    | head -1 \
    | cut -d '"' -f 4)

[[ -z "$LATEST_URL" ]] && { echo "[!] Aisaka encountered an error, please DM vancyfancy on Discord."; exit 1; }

curl -fsSL "$LATEST_URL" -o "$INSTALL_DIR/AisakaLauncher.exe" || { echo "[!] Aisaka encountered an error, please DM vancyfancy on Discord."; exit 1; }

echo "[*] Installing prerequisites..."

if ! command -v wine &>/dev/null && ! command -v wine64 &>/dev/null; then
    pm="unknown"
    command -v apt-get &>/dev/null && pm="apt"
    command -v dnf     &>/dev/null && pm="dnf"
    command -v pacman  &>/dev/null && pm="pacman"
    command -v zypper  &>/dev/null && pm="zypper"
    command -v emerge  &>/dev/null && pm="emerge"

    case "$pm" in
        apt)
            sudo dpkg --add-architecture i386 &>/dev/null
            sudo apt-get update -qq &>/dev/null
            sudo apt-get install -y wine wine32 wine64 xdg-utils &>/dev/null
            ;;
        dnf)
            sudo dnf install -y wine xdg-utils &>/dev/null
            ;;
        pacman)
            sudo pacman -Sy --noconfirm wine xdg-utils &>/dev/null
            ;;
        zypper)
            sudo zypper install -y wine xdg-utils &>/dev/null
            ;;
        emerge)
            sudo emerge --ask=n app-emulation/wine-staging &>/dev/null
            ;;
        *)
            echo "[!] Aisaka encountered an error, please DM vancyfancy on Discord."
            exit 1
            ;;
    esac
fi

echo "[+] Setting Aisaka up..."

SCRIPT_PATH="$(realpath "$0")"
mkdir -p "$DESKTOP_APPS" || { echo "[!] Aisaka encountered an error, please DM vancyfancy on Discord."; exit 1; }

cat > "$ENTRY_FILE" <<EOF
[Desktop Entry]
Name=Aisaka Player
Exec=bash $SCRIPT_PATH --uri %u
Type=Application
Terminal=false
MimeType=x-scheme-handler/aisaka-player
Categories=Game
NoDisplay=true
EOF

cat > "$UNINSTALL_ENTRY_FILE" <<EOF
[Desktop Entry]
Name=Uninstall Aisaka Player
Exec=bash $SCRIPT_PATH --uninstall
Type=Application
Terminal=true
Categories=Game
EOF

update-desktop-database "$DESKTOP_APPS" &>/dev/null || true
xdg-mime default aisaka-player.desktop x-scheme-handler/aisaka-player &>/dev/null || true

echo "[!] Aisaka setup finished!"