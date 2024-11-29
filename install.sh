#!/bin/bash

# Проверка, что скрипт выполняется с правами root
if [ "$(id -u)" != "0" ]; then
    echo "Скрипт должен выполняться с правами root!"
    exit 1
fi

# Установка необходимых пакетов
install_packages() {
    echo "Установка необходимых пакетов..."
    dnf update -y
    dnf install -y epel-release
    dnf install -y wget curl tar gcc gcc-c++ make cmake git unzip python3 python3-pip \
        dmidecode htop mc screen tmux psmisc ncurses-compat-libs \
        libtommath p7zip chrony iptables-services fail2ban
}

# Удаление ненужных пакетов
remove_packages() {
    echo "Удаление ненужных пакетов..."
    dnf remove -y postfix sendmail
    dnf autoremove -y
}

# Настройка Firewall
setup_firewall() {
    echo "Настройка Firewall..."
    systemctl enable iptables
    systemctl start iptables

    iptables -F
    iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A INPUT -m state --state INVALID -j DROP
    iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
    iptables -A INPUT -p udp --dport 4242 -j ACCEPT
    iptables -A INPUT -p tcp --dport ssh -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -j DROP

    service iptables save
}

# Настройка Chrony (синхронизация времени)
setup_time() {
    echo "Настройка синхронизации времени..."
    systemctl enable chronyd
    systemctl start chronyd
    timedatectl set-timezone Etc/UTC
}

# Включение Swap, если он не включен
enable_swap() {
    if ! free | awk '/^Swap:/ {exit !$2}'; then
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo "/swapfile none swap sw 0 0" >>/etc/fstab
    fi
}

# Установка MoonTrader
install_mt() {
    local folder="/opt/moontrader"
    local link="https://cdn3.moontrader.com/beta/linux-x86_64/MoonTrader-linux-x86_64.tar.xz"

    echo "Установка MoonTrader..."
    mkdir -p "$folder"
    wget -O "$folder/MoonTrader.tar.xz" "$link"
    tar -xpJf "$folder/MoonTrader.tar.xz" -C "$folder"
    rm "$folder/MoonTrader.tar.xz"

    chmod +x "$folder/MTCore"
    ln -s "$folder/MTCore" /usr/bin/MoonTrader
}

# Основной процесс установки
main() {
    install_packages
    remove_packages
    setup_firewall
    setup_time
    enable_swap
    install_mt
    echo "Установка завершена. Используйте команду MoonTrader для запуска."
}

main
