#!/bin/bash
# Panasonic CF-SR Fan Control 完整解除安裝腳本

if [ "$EUID" -ne 0 ]; then
  echo "❌ 請使用 sudo 執行此腳本。"
  exit 1
fi

echo "=> [1/4] 停止並停用 Systemd 系統服務..."
systemctl stop cf-sr-thermal.service 2>/dev/null
systemctl disable cf-sr-thermal.service 2>/dev/null

echo "=> [2/4] 從記憶體中卸載核心模組..."
modprobe -r panasonic_sr 2>/dev/null

echo "=> [3/4] 刪除系統路徑下的執行檔、服務設定與模組檔案..."
rm -f /etc/systemd/system/cf-sr-thermal.service
rm -f /usr/local/bin/cf-sr-thermal.sh
rm -f /lib/modules/$(uname -r)/updates/dkms/panasonic_sr.ko

echo "=> [4/4] 重新載入系統設定並更新模組依賴樹..."
systemctl daemon-reload
depmod -a

echo ""
echo "=================================================================="
echo "🗑️ 解除安裝全部完成！系統已恢復原狀。"
echo "=================================================================="