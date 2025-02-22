# DNS Changer - Easily Change Your System's DNS  

`dnser` allows you to **quickly change your system's DNS** settings using various DNS providers. It supports **NetworkManager, systemd-resolved, and resolv.conf** methods.  

## 🚀 Features  
✅ Change DNS to well-known providers (Google, Cloudflare, Shecan, etc.)  
✅ Automatically detects your system's DNS management method  
✅ Clears and resets DNS settings for a fresh configuration  
✅ Works on **Ubuntu, Debian, Arch, and most Linux distros**  

---

## 📥 Installation  

To download and install the latest release, run:  

```bash
sudo wget -O /usr/local/bin/dnser https://github.com/mojtabana/dnser/releases/latest/download/dnser.sh
sudo chmod +x /usr/local/bin/dnser
```


## ⚡ Usage  

### 1️⃣ **Check DNS Status**    
```bash
sudo dnser dns status
```

### 1️⃣ **clear all DNS settings**    
```bash
sudo dnser dns clear --dns
```
### 1️⃣ **clear DNS caches**    
```bash
sudo dnser dns clear --cache
```

### 1️⃣ **set DNS**    
```bash
sudo dnser dns set
```