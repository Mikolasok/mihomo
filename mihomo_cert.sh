#!/bin/bash

DOMAIN="b.xgt.dpdns.org"

ACME_HOME="$HOME/.acme.sh"
ACME="$ACME_HOME/acme.sh"
ACME_EMAIL="your@email.com"
CERT_PATH="/usr/local/etc/mihomo"
KEY_FILE="$CERT_PATH/key.pem"
CERT_FILE="$CERT_PATH/cert.pem"
CRON_JOB="0 3 * * 1 /usr/bin/truncate -s 0 /usr/local/etc/mihomo/mihomo_cert.log && /bin/bash /root/mihomo_cert.sh >> /usr/local/etc/mihomo/mihomo_cert.log 2>&1"

# 检查并安装 curl
check_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        apt-get update && apt-get install -y curl
    fi
}

# 安装 acme.sh
install_acme() {
    if [[ ! -f "$ACME" ]]; then
        curl https://get.acme.sh | sh -s email="$ACME_EMAIL"
    fi
    export PATH="$ACME_HOME:$PATH"
}

# 创建证书目录
prepare_dir() {
    if [[ ! -d "$CERT_PATH" ]]; then
        mkdir -p "$CERT_PATH"
    fi
}

# 设置 cron 任务（自动续期）
set_cron() {
    chmod +x /root/0.sh 2>/dev/null

    if crontab -l 2>/dev/null | grep -Fq "/root/mihomo_cert.sh"; then
        return 0
    else
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    fi
}

# 设置 CA
set_ca() {
    $ACME --set-default-ca --server letsencrypt
}

# 申请证书
issue_cert() {
    if ! $ACME --issue --standalone -d "$DOMAIN" -k ec-256 --force; then
        exit 1
    fi
}

# 安装证书
install_cert() {
    echo ">>> 安装证书..."

    if $ACME --install-cert -d "$DOMAIN" \
        --key-file "$KEY_FILE" \
        --fullchain-file "$CERT_FILE" \
        --reloadcmd "systemctl restart mihomo"; then
        echo "✔ 证书安装成功"
    else
        echo "❌ 证书安装失败"
    fi
}

# ================= 主流程 =================
main() {
    check_curl
    install_acme
    prepare_dir
    set_cron
    set_ca
    issue_cert
    install_cert
    echo "🎉 全部流程完成"
}

main
