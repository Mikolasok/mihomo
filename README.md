- **安装 mihomo**
```
wget -O /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-amd64-compatible-v1.19.30.gz \
&& gunzip /usr/local/bin/mihomo.gz \
&& chmod +x /usr/local/bin/mihomo
```
- **开启 BBR**
```
cat >> /etc/sysctl.conf << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
```
```
sysctl -p
```
```
sysctl net.ipv4.tcp_congestion_control
```
- **配置 systemd 任务**
```
cat > /etc/systemd/system/mihomo.service << 'EOF'
[Unit]
Description=mihomo Daemon, Another Clash Kernel.
After=network.target NetworkManager.service systemd-networkd.service iwd.service

[Service]
Type=simple
LimitNPROC=500
LimitNOFILE=1000000
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE
Restart=always
ExecStartPre=/usr/bin/sleep 1s
Environment=SAFE_PATHS=/var/lib/caddy/.local/share/caddy/
ExecStart=/usr/local/bin/mihomo -d /usr/local/etc/mihomo
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
```
```
systemctl daemon-reload
```
```
systemctl enable mihomo
```
- **创建 mihomo 配置文件**
```
mkdir -p /usr/local/etc/mihomo && touch /usr/local/etc/mihomo/config.yaml
```
- **mihomo 配置文件示例**
```
log-level: info
listeners:
  - name: anytls-in
    type: anytls
    port: 10818
    listen: 0.0.0.0
    users:
      username1: "password1"
      username2: "password2"
    certificate: /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/luna.example.com/luna.example.com.crt
    private-key: /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/luna.example.com/luna.example.com.key
    padding-scheme: |
      stop=8
      0=30-30
      1=100-400
      2=400-500,c,500-1000,c,500-1000,c,500-1000,c,500-1000
      3=9-9,500-1000
      4=500-1000
      5=500-1000
      6=500-1000
      7=500-1000
proxies:
  - name: "direct"
    type: direct
```
- **生成强密码**
- ***关闭 Bash 的历史展开***
```
set +H
```
- ***生成密码***
```
python3 -c "import secrets,string; c=string.ascii_letters+string.digits+'!@#$%^&*'; a=[secrets.choice(string.ascii_uppercase),secrets.choice(string.ascii_lowercase),secrets.choice(string.digits),secrets.choice('!@#$%^&*')]+[secrets.choice(c) for _ in range(14)]; secrets.SystemRandom().shuffle(a); print(''.join(a))"
```
- ***恢复 Bash 的历史展开***
```
set -H
```
- **mihomo 服务管理**
```
systemctl start mihomo
```
```
systemctl stop mihomo
```
```
systemctl status mihomo
```
