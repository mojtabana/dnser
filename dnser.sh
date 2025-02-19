#!/bin/bash

# Colors
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Configurations
RESOLV_CONF="/etc/resolv.conf"
BACKUP_FILE="/etc/resolv.conf.backup"

# DNS Presets
SHECAN1="178.22.122.100"
SHECAN2="185.51.200.2"
FOUR_OH_THREE1="10.202.10.202"
FOUR_OH_THREE2="10.202.10.102"
GOOGLE1="8.8.8.8"
GOOGLE2="8.8.4.4"
CLOUDFLARE1="1.1.1.1"
CLOUDFLARE2="1.0.0.1"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
fi

# Function to display the welcome message
show_welcome() {
    echo -e "${CYAN}**************************************"
    echo -e "*                                    *"
    echo -e "*      ${GREEN}Welcome to the DNS Changer${CYAN}      *"
    echo -e "*                                    *"
    echo -e "**************************************"
    echo -e "${YELLOW}Your DNS will be updated beautifully!${RESET}"
    echo -e "${CYAN}This tool allows you to change your system's DNS quickly and easily!${RESET}"
}

# Function to detect DNS management system
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

# Function to clear DNS cache
clear_dns_cache() {
    if command -v resolvectl &>/dev/null; then
        echo -e "${YELLOW}Clearing DNS cache using systemd-resolved...${RESET}"
        resolvectl flush-caches
        echo -e "${GREEN}DNS cache cleared successfully!${RESET}"
    else
        echo -e "${RED}No DNS cache management tool found!${RESET}"
    fi
}

# Function to remove previous DNS settings
clear_previous_dns() {
    manager=$(detect_dns_manager)

    echo -e "${YELLOW}Detected DNS Manager: ${GREEN}$manager${RESET}"

    case "$manager" in
    networkmanager)
        echo -e "${YELLOW}Removing DNS settings in NetworkManager...${RESET}"
        active_connections=$(nmcli -t -f NAME con show --active)
        for connection in $active_connections; do
            # Remove DNS settings and re-apply network settings
            nmcli connection modify "$connection" ipv4.dns ""
            nmcli connection up "$connection"
        done
        echo -e "${GREEN}DNS settings removed successfully in NetworkManager!${RESET}"
        ;;

    systemd-resolved)
        echo -e "${YELLOW}Removing DNS settings in systemd-resolved...${RESET}"
        resolvectl dns $(resolvectl status | grep "Link" | awk '{print $2}') --reset
        echo -e "${GREEN}DNS settings removed successfully in systemd-resolved!${RESET}"
        ;;

    resolv.conf)
        echo -e "${YELLOW}Removing DNS settings in /etc/resolv.conf...${RESET}"
        >"$RESOLV_CONF"
        echo -e "${GREEN}DNS settings removed successfully from /etc/resolv.conf!${RESET}"
        ;;

    *)
        echo -e "${RED}Unknown DNS management system. Please update manually.${RESET}"
        exit 1
        ;;
    esac
}

# Function to change DNS based on detected system
change_dns() {
    local dns1="$1"
    local dns2="$2"

    manager=$(detect_dns_manager)

    echo -e "${YELLOW}Detected DNS Manager: ${GREEN}$manager${RESET}"

    case "$manager" in
    networkmanager)
        echo -e "${YELLOW}Updating DNS via NetworkManager...${RESET}"
        active_connections=$(nmcli -t -f NAME con show --active)
        for connection in $active_connections; do
            nmcli connection modify "$connection" ipv4.dns "$dns1 $dns2"
            nmcli connection up "$connection"
        done
        echo -e "${GREEN}DNS updated successfully!${RESET}"
        ;;

    systemd-resolved)
        echo -e "${YELLOW}Updating DNS via systemd-resolved...${RESET}"
        resolvectl dns $(resolvectl status | grep "Link" | awk '{print $2}') --reset
        resolvectl dns $(resolvectl status | grep "Link" | awk '{print $2}') "$dns1 $dns2"
        echo -e "${GREEN}DNS updated successfully!${RESET}"
        ;;

    resolv.conf)
        echo -e "${YELLOW}Updating /etc/resolv.conf...${RESET}"
        cp "$RESOLV_CONF" "$BACKUP_FILE"
        >"$RESOLV_CONF"
        echo -e "nameserver $dns1\nnameserver $dns2" >"$RESOLV_CONF"
        chattr +i "$RESOLV_CONF"
        echo -e "${GREEN}DNS updated successfully!${RESET}"
        ;;

    *)
        echo -e "${RED}Unknown DNS management system. Please update manually.${RESET}"
        exit 1
        ;;
    esac
}

# Function to show selection menu
show_menu() {
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
    2) change_dns "$FOUR_OH_THREE1" "$FOUR_OH_THREE2" ;;
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

# Display the welcome message and then check arguments
show_welcome

# Parse command-line arguments
case "$1" in
dns)
    case "$2" in
    --status)
        echo -e "${CYAN}Current DNS Settings:${RESET}"
        cat "$RESOLV_CONF"
        ;;
    --set)
        show_menu
        ;;
    --clear-cache)
        clear_dns_cache
        ;;
    --clear-dns)
        clear_previous_dns
        ;;
    *)
        echo -e "${RED}Invalid option! Usage: $0 dns [--status | --set | --clear-cache | --clear-dns]${RESET}"
        exit 1
        ;;
    esac
    ;;
*)
    echo -e "${RED}Usage: $0 dns [--status | --set | --clear-cache | --clear-dns]${RESET}"
    exit 1
    ;;
esac
