#!/bin/bash

# 清理日志脚本

LOG_DIR="/workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2/logs"

echo "========================================"
echo "🧹 清理日志文件"
echo "========================================"
echo ""

if [ ! -d "$LOG_DIR" ]; then
    echo "❌ 日志目录不存在: $LOG_DIR"
    exit 1
fi

# 显示当前日志文件
echo "📁 当前日志文件:"
if ls -lh "$LOG_DIR"/*.log > /dev/null 2>&1; then
    ls -lh "$LOG_DIR"/*.log | awk '{print "  " $9 " - " $5}'
    echo ""
    
    # 询问是否确认
    read -p "⚠️  确认要删除所有日志文件吗? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo ""
        echo "正在清理日志..."
        rm -f "$LOG_DIR"/*.log
        echo "✅ 日志已清理"
    else
        echo ""
        echo "❌ 取消清理"
    fi
else
    echo "  没有日志文件需要清理"
fi
echo ""
echo "========================================"






