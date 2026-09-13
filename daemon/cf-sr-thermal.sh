#!/bin/bash
HIGH_TEMP=65000
LOW_TEMP=50000

ZONE_PATH=""
for z in /sys/class/thermal/thermal_zone*; do
    if [ "$(cat $z/type 2>/dev/null)" = "x86_pkg_temp" ]; then
        ZONE_PATH="$z/temp"
        break
    fi
done

STATE=1
systemctl restart thermald.service
echo 1 > /sys/class/panasonic_sr/fan_control/sefm

while true; do
    # 取得 Ubuntu 當前的電源模式 (若指令不存在則預設為 balanced)
    PROFILE=$(powerprofilesctl get 2>/dev/null || echo "balanced")

    if [ "$PROFILE" = "performance" ]; then
        # 性能模式：無視溫度限制，強制開啟高效能風扇 (0)
        if [ "$STATE" -eq 1 ]; then
            systemctl restart thermald.service
            echo 0 > /sys/class/panasonic_sr/fan_control/sefm
            STATE=0
        fi
    else
        # 平衡 (balanced) 或省電 (power-saver) 模式：執行原本的動態溫控邏輯
        if [ -n "$ZONE_PATH" ]; then
            TEMP=$(cat $ZONE_PATH 2>/dev/null)
        else
            TEMP=0
        fi
        
        if [ -z "$TEMP" ] || [ "$TEMP" -eq 0 ]; then
            sleep 3
            continue
        fi

        # 溫度飆高 (>= 70°C) 且目前為靜音 -> 先重啟 thermald 放開限制，再開高效能風扇 (0)
        if [ "$TEMP" -ge "$HIGH_TEMP" ] && [ "$STATE" -eq 1 ]; then
            systemctl restart thermald.service
            echo 0 > /sys/class/panasonic_sr/fan_control/sefm
            STATE=0
        # 溫度降溫 (<= 55°C) 且目前為高效能 -> 先重啟 thermald 收回限制，再切回靜音風扇 (1)
        elif [ "$TEMP" -le "$LOW_TEMP" ] && [ "$STATE" -eq 0 ]; then
            systemctl restart thermald.service
            echo 1 > /sys/class/panasonic_sr/fan_control/sefm
            STATE=1
        fi
    fi
    
    sleep 3
done