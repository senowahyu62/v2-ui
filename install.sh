#!/usr/bin/env bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red} error: ${plain} harus menJadi root user untuk menjalankan skrip ini!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "Versi sistem ${red} tidak didukung${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Silakan gunakan sistem versi CentOS 7 atau lebih tinggi! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Silakan gunakan sistem versi Ubuntu 16 atau lebih tinggi! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Silakan gunakan sistem versi Debian 8 atau lebih tinggi! ${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_v2ray() {
    echo -e "${green} mulai menginstal V2ray${plain}"
    bash <(curl -L -s https://install.direct/go.sh)
    if [[ $? -ne 0 ]]; then
        echo -e "${red}pemasangan v2ray gagal, harap periksa log ${plain}"
        exit 1
    fi
    systemctl enable v2ray
    systemctl start v2ray
}

close_firewall() {
    if [[ x"${release}" == x"centos" ]]; then
        systemctl stop firewalld
        systemctl disable firewalld
    elif [[ x"${release}" == x"ubuntu" ]]; then
        ufw disable
    elif [[ x"${release}" == x"debian" ]]; then
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -F
    fi
}

install_v2-ui() {
    systemctl stop v2-ui
    cd /usr/local/
    if [[ -e /usr/local/v2-ui/ ]]; then
        rm /usr/local/v2-ui/ -rf
    fi
    wget -N --no-check-certificate -O /usr/local/v2-ui-linux.tar.gz https://github.com/sprov065/v2-ui/releases/download/${last_version}/v2-ui-linux.tar.gz
    tar zxvf v2-ui-linux.tar.gz
    rm v2-ui-linux.tar.gz -f
    cd v2-ui
    chmod +x v2-ui
    cp -f v2-ui.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable v2-ui
    systemctl start v2-ui
	echo -e "Instalasi selesai, panel telah diaktifkan,"
    gema -e ""
    echo -e "Jika ini adalah instalasi baru, port web default adalah ${green}65432${plain}, dan nama pengguna dan sandi keduanya ${green}admin${plain} secara default.
    echo -e "${yellow}Pastikan port ini tidak dipakai program lain${plain}"
    gema -e ""
    gema -e ""
    curl -o /usr/bin/v2-ui -Ls https://raw.githubusercontent.com/senowahyu62/v2-ui/master/v2-ui.sh
    chmod +x /usr/bin/v2-ui
    echo -e "metode penggunaan skrip manajemen v2-ui: "
    echo -e "----------------------------------------------------------- "
    echo -e "v2-ui 				- show menu manajemen (fungsi lainnya)"
    echo -e "v2-ui star 		- start panel v2-ui"
    echo -e "v2-ui stop			- stop panel v2-ui"
    echo -e "v2-ui restart		- restart panel v2-ui"
    echo -e "v2-ui status		- lihat status v2-ui"
    echo -e "v2-ui aktifkan		- set v2-ui untuk memulai secara otomatis setelah booting"
    echo -e "v2-ui nonaktifkan	- batalkan boot v2-ui dari awal"
    echo -e "v2-ui log			- lihat log v2-ui"
    echo -e "v2-ui update		- update panel v2-ui"
    echo -e "v2-ui install		- install panel v2-ui"
    echo -e "v2-ui uninstall	- uninstall panel v2-ui"
    echo -e "----------------------------------------------------------- "
}

echo -e "${green}mulai menginstal${plain}"
install_base
install_v2ray
install_v2-ui
