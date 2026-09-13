#!/bin/bash
# Panasonic CF-SR Secure Boot 安裝腳本

if [ "$EUID" -ne 0 ]; then
  echo "❌ 請使用 sudo 執行此腳本。"
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DEST="/lib/modules/$(uname -r)/updates/dkms"

echo "=> [1/6] 安裝編譯相依套件與工具..."
apt-get update
apt-get install -y build-essential linux-headers-$(uname -r) mokutil openssl thermald

echo "=> [2/6] 編譯核心模組..."
cd "$BASE_DIR/module"
make

echo "=> [3/6] 檢查或準備 MOK 數位簽章憑證..."
if [ ! -f /root/MOK.priv ] || [ ! -f /root/MOK_der.der ]; then
    openssl req -new -x509 -newkey rsa:2048 -keyout /root/MOK.priv -out /root/MOK.der -nodes -days 36500 -subj "/CN=Panasonic CF-SR Custom Key/"
    openssl x509 -in /root/MOK.der -outform DER -out /root/MOK_der.der
    echo "🔑 已產生新的 MOK 憑證，並轉為標準 DER 格式。"
fi

echo "=> [4/6] 進行模組數位簽章並安裝至核心目錄..."
/usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 /root/MOK.priv /root/MOK_der.der panasonic_sr.ko
mkdir -p "$MODULE_DEST"
cp panasonic_sr.ko "$MODULE_DEST/"
depmod -a
modprobe -r panasonic_sr 2>/dev/null
modprobe panasonic_sr

# === 新增的清理步驟 ===
echo "=> 🧹 清理編譯產生的中間與暫存檔案..."
make clean
# ======================

echo "=> [5/6] 部署動態溫控腳本..."
cp "$BASE_DIR/daemon/cf-sr-thermal.sh" /usr/local/bin/
chmod +x /usr/local/bin/cf-sr-thermal.sh

echo "=> [6/6] 註冊並啟動 Systemd 系統服務..."
cp "$BASE_DIR/systemd/cf-sr-thermal.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now cf-sr-thermal.service

echo ""
echo "=================================================================="
echo "🎉 部署全部完成！目錄已保持乾淨。"
echo "您可以透過以下指令檢查服務運作狀態："
echo "  systemctl status cf-sr-thermal.service"
echo "=================================================================="