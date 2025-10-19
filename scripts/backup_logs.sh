#!/bin/bash

# 备份日志脚本

LOG_DIR="/workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2/logs"
BACKUP_DIR="/workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2/logs/backups"

echo "========================================"
echo "💾 备份日志文件"
echo "========================================"
echo ""

if [ ! -d "$LOG_DIR" ]; then
    echo "❌ 日志目录不存在: $LOG_DIR"
    exit 1
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 生成备份文件名（带时间戳）
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/logs_backup_${TIMESTAMP}.tar.gz"

# 检查是否有日志文件
if ls "$LOG_DIR"/*.log > /dev/null 2>&1; then
    echo "📦 创建备份..."
    tar -czf "$BACKUP_FILE" -C "$LOG_DIR" $(ls "$LOG_DIR"/*.log 2>/dev/null | xargs -n 1 basename)
    
    if [ $? -eq 0 ]; then
        echo "✅ 备份成功: $BACKUP_FILE"
        echo "   大小: $(du -h "$BACKUP_FILE" | cut -f1)"
        echo ""
        
        # 询问是否清理原日志
        read -p "是否清理原日志文件? (y/N): " clean
        
        if [ "$clean" = "y" ] || [ "$clean" = "Y" ]; then
            rm -f "$LOG_DIR"/*.log
            echo "✅ 原日志已清理"
        fi
    else
        echo "❌ 备份失败"
    fi
else
    echo "⚠️  没有日志文件需要备份"
fi

echo ""
echo "📁 备份目录: $BACKUP_DIR"
if ls -lh "$BACKUP_DIR"/*.tar.gz > /dev/null 2>&1; then
    echo ""
    echo "现有备份:"
    ls -lht "$BACKUP_DIR"/*.tar.gz | head -5 | awk '{print "  " $9 " - " $5 " (" $6, $7, $8 ")"}'
fi

echo ""
echo "========================================"






