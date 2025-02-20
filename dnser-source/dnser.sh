#!/bin/bash

# Colors
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# ASCII Art
ART=$(cat <<'EOF'
      _                      
     | |                     
   __| |_ __  ___  ___ _ __  
  / _` | '_ \/ __|/ _ \ '__| 
 | (_| | | | \__ \  __/ |    
  \__,_|_| |_|___/\___|_|    
                             
EOF
)
# Function to display the ASCII Art before every task
display_art() {
    echo -e "${CYAN}$ART${RESET}"
}

show_welcome() {
    display_art
    echo -e "${CYAN}**************************************"
    echo -e "*                                    *"
    echo -e "*      ${GREEN}Welcome to the DNS Changer${CYAN}      *"
    echo -e "*                                    *"
    echo -e "**************************************"
    echo -e "${YELLOW}Your DNS will be updated beautifully!${RESET}"
    echo -e "${CYAN}This tool allows you to change your system's DNS quickly and easily!${RESET}"
}

# DNS Presets
FOUR_OH_THREE1="10.202.10.202"
FOUR_OH_THREE2="10.202.10.102"
SHECAN1="178.22.122.100"
SHECAN2="185.51.200.2"
GOOGLE1="8.8.8.8"
GOOGLE2="8.8.4.4"
CLOUDFLARE1="1.1.1.1"
CLOUDFLARE2="1.0.0.1"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
fi

# Detect DNS management system
detect_dns_manager() {
    if command -v nmcli &>/dev/null; then
        echo "networkmanager"
    elif systemctl is-active --quiet systemd-resolved; then
        echo "systemd-resolved"
    elif [ -f /etc/resolv.conf ]; then
        echo "resolv.conf"
    else
        echo "unknown"
    fi
}

# Fully clear previous DNS settings
clear_previous_dns() {
    display_art
    echo -e "${YELLOW}Clearing previous DNS settings...${RESET}"

    # 1️⃣ Clear NetworkManager DNS settings
    if command -v nmcli &>/dev/null; then
        active_connections=$(nmcli -t -f NAME con show --active)
        for connection in $active_connections; do
            nmcli connection modify "$connection" ipv4.dns ""
            nmcli connection modify "$connection" ipv4.ignore-auto-dns no
            nmcli connection up "$connection"
        done
    fi

    # 2️⃣ Remove Global DNS from systemd-resolved
    if [ -f /etc/systemd/resolved.conf ]; then
        echo -e "${YELLOW}Removing global DNS from systemd-resolved...${RESET}"
        sed -i '/^DNS=/d' /etc/systemd/resolved.conf # Remove existing DNS entries
        sed -i '/^FallbackDNS=/d' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved # Restart service
    fi

    # 3️⃣ Reset per-interface DNS settings
    if command -v resolvectl &>/dev/null; then
        for iface in $(resolvectl status | grep "Link" | awk '{print $2}'); do
            resolvectl dns "$iface" "" # Clear DNS for each interface
        done
        resolvectl flush-caches # Flush cache
    fi

    # 4️⃣ Reset /etc/resolv.conf
    if [ -L /etc/resolv.conf ]; then
        rm -f /etc/resolv.conf
    fi
    touch /etc/resolv.conf
    echo "nameserver 127.0.0.53" >/etc/resolv.conf # Use systemd stub resolver

    echo -e "${GREEN}DNS settings cleared successfully!${RESET}"
}

# Change DNS to new settings
change_dns() {
    primary_dns="$1"
    secondary_dns="$2"

    echo -e "${YELLOW}Setting new DNS: ${GREEN}$primary_dns, $secondary_dns${RESET}"

    # 1️⃣ Detect DNS Manager
    manager=$(detect_dns_manager)

    # 2️⃣ Apply DNS for NetworkManager
    if command -v nmcli &>/dev/null; then
        active_connections=$(nmcli -t -f NAME con show --active)
        for connection in $active_connections; do
            nmcli connection modify "$connection" ipv4.dns "$primary_dns $secondary_dns"
            nmcli connection modify "$connection" ipv4.ignore-auto-dns yes
            nmcli connection up "$connection"
        done
    fi

    # 3️⃣ Apply Global DNS in systemd-resolved
    if [ -f /etc/systemd/resolved.conf ]; then
        echo -e "${YELLOW}Updating /etc/systemd/resolved.conf...${RESET}"
        sed -i '/^DNS=/d' /etc/systemd/resolved.conf
        sed -i '/^FallbackDNS=/d' /etc/systemd/resolved.conf
        echo "DNS=$primary_dns $secondary_dns" >>/etc/systemd/resolved.conf
        systemctl restart systemd-resolved
    fi

    # 4️⃣ Apply DNS per interface in systemd-resolved
    if command -v resolvectl &>/dev/null; then
        for iface in $(resolvectl status | grep "Link" | awk '{print $2}'); do
            resolvectl dns "$iface" "$primary_dns" "$secondary_dns"
        done
        resolvectl flush-caches
    fi

    # 5️⃣ Update /etc/resolv.conf
    if [ -L /etc/resolv.conf ]; then
        rm -f /etc/resolv.conf
    fi
    echo -e "nameserver $primary_dns\nnameserver $secondary_dns" >/etc/resolv.conf

    echo -e "${GREEN}DNS changed successfully to $primary_dns, $secondary_dns!${RESET}"
}

# Show current DNS settings
show_dns_status() {
    display_art
    echo -e "${CYAN}Current DNS Settings:${RESET}"
    resolvectl status | grep -E "DNS Servers|Link"
    cat /etc/resolv.conf
}

# CLI menu for setting DNS
show_menu() {
    display_art
    echo -e "${CYAN}Select a DNS provider:${RESET}"
    echo "1) Shecan (🇮🇷 178.22.122.100, 185.51.200.2)"
    echo "2) 403 (🇮🇷 10.202.10.202, 10.202.10.102)"
    echo "3) Google (🌍 8.8.8.8, 8.8.4.4)"
    echo "4) Cloudflare (🌍 1.1.1.1, 1.0.0.1)"
    echo "5) Enter custom DNS"
    echo "6) Exit"

    read -p "Enter your choice [1-6]: " choice

    case "$choice" in
    1) change_dns "$SHECAN1" "$SHECAN2" ;;
    2) change_dns "$FOUR_OH_THREE1" "$FOUR_OH_THREE2" ;; # Added 403 DNS
    3) change_dns "$GOOGLE1" "$GOOGLE2" ;;
    4) change_dns "$CLOUDFLARE1" "$CLOUDFLARE2" ;;
    5)
        read -p "Enter primary DNS: " custom_dns1
        read -p "Enter secondary DNS: " custom_dns2
        change_dns "$custom_dns1" "$custom_dns2"
        ;;
    6)
        echo -e "${RED}Exiting...${RESET}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option!${RESET}"
        exit 1
        ;;
    esac
}

# Command-line arguments
case "$1" in
help)
    display_art
    echo -e "${CYAN}Available options:${RESET}"
    echo "help      - Show this help message"
    echo "set       - Set DNS using a selected provider"
    echo "clear --cache   - Clear DNS cache"
    echo "clear --dns     - Clear previous DNS settings"
    echo "status    - Show current DNS settings"
    ;;
dns)
    case "$2" in
    set)
        show_menu
        ;;
    status)
        show_dns_status
        ;;
    clear)
        if [ "$3" == "--cache" ]; then
            resolvectl flush-caches
            echo -e "${GREEN}DNS cache cleared!${RESET}"
        elif [ "$3" == "--dns" ]; then
            clear_previous_dns
        else
            echo -e "${RED}Invalid option for clear. Use --cache or --dns.${RESET}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}Invalid option!${RESET}"
        exit 1
        ;;
    esac
    ;;
*)
    echo -e "${RED}Usage: $0 dns [help | set | status | clear --cache | clear --dns]${RESET}"
    exit 1
    ;;
esac
