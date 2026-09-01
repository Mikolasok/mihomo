# Mihomo 安装与配置指南

## 1. 安装 Mihomo

下载并安装 Mihomo：

```bash
wget -O /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-amd64-compatible-v1.19.30.gz \
&& gunzip /usr/local/bin/mihomo.gz \
&& chmod +x /usr/local/bin/mihomo
```

---

## 2. 开启 BBR

将 BBR 配置写入 `/etc/sysctl.conf`：

```bash
cat >> /etc/sysctl.conf << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
```

加载新的内核参数：

```bash
sysctl -p
```

检查 TCP 拥塞控制算法：

```bash
sysctl net.ipv4.tcp_congestion_control
```

如果输出：

```text
net.ipv4.tcp_congestion_control = bbr
```

说明 BBR 已启用。

---

## 3. 配置 Mihomo systemd 服务

创建 Mihomo systemd 服务：

```bash
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

重新加载 systemd：

```bash
systemctl daemon-reload
```

设置 Mihomo 开机自启：

```bash
systemctl enable mihomo
```

---

## 4. 创建 Mihomo 配置目录

创建配置目录及配置文件：

```bash
mkdir -p /usr/local/etc/mihomo && touch /usr/local/etc/mihomo/config.yaml
```

---

## 5. 配置 Mihomo

编辑配置文件：

```bash
vim /usr/local/etc/mihomo/config.yaml
```

写入以下配置：

```yaml
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

> **注意：**
>
> * `luna.example.com` 请替换为你的实际域名。
> * `certificate` 和 `private-key` 必须对应实际存在的证书文件。
> * `username1`、`username2` 以及对应密码请根据实际需求修改。
> * 端口 `10818` 可以根据实际需求调整。

---

## 6. 生成强密码

### 6.1 关闭 Bash 历史展开

由于密码生成字符中包含 `!`，建议先关闭 Bash 的历史展开：

```bash
set +H
```

### 6.2 生成随机强密码

执行：

```bash
python3 -c "import secrets,string; c=string.ascii_letters+string.digits+'!@#$%^&*'; a=[secrets.choice(string.ascii_uppercase),secrets.choice(string.ascii_lowercase),secrets.choice(string.digits),secrets.choice('!@#$%^&*')]+[secrets.choice(c) for _ in range(14)]; secrets.SystemRandom().shuffle(a); print(''.join(a))"
```

该命令会生成一个：

* 长度：18 位
* 至少包含 1 个大写字母
* 至少包含 1 个小写字母
* 至少包含 1 个数字
* 至少包含 1 个特殊字符

的随机密码。

例如：

```text
A7@kP2!xQ9#mL4$vNz
```

> **建议：** 生成密码后，将密码保存到安全的密码管理器中，不要直接记录在公开文档或聊天记录中。

### 6.3 恢复 Bash 历史展开

密码生成完成后执行：

```bash
set -H
```

---

## 7. 启动 Mihomo

启动服务：

```bash
systemctl start mihomo
```

---

## 8. 查看 Mihomo 服务状态

执行：

```bash
systemctl status mihomo
```

如果服务正常运行，可以看到类似：

```text
● mihomo.service - mihomo Daemon, Another Clash Kernel.
     Loaded: loaded (/etc/systemd/system/mihomo.service; enabled)
     Active: active (running)
```

其中：

```text
Active: active (running)
```

表示 Mihomo 当前正在正常运行。

---

## 9. 停止 Mihomo

停止服务：

```bash
systemctl stop mihomo
```

---

## 10. 常用服务管理命令

### 启动

```bash
systemctl start mihomo
```

### 停止

```bash
systemctl stop mihomo
```

### 重启

```bash
systemctl restart mihomo
```

### 查看状态

```bash
systemctl status mihomo
```

### 设置开机自启

```bash
systemctl enable mihomo
```

### 取消开机自启

```bash
systemctl disable mihomo
```

### 查看实时日志

```bash
journalctl -u mihomo -f
```

### 查看最近日志

```bash
journalctl -u mihomo --no-pager -n 100
```

### 检查配置文件

```bash
mihomo -d /usr/local/etc/mihomo -t
```

---
