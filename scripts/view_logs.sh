#!/bin/bash

# 日志查看脚本

LOG_DIR="/workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2/logs"

echo "========================================"
echo "📊 系统日志摘要"
echo "========================================"
echo ""

if [ ! -d "$LOG_DIR" ]; then
    echo "❌ 日志目录不存在: $LOG_DIR"
    exit 1
fi

# 检查日志文件
echo "📁 日志文件列表:"
if ls -lh "$LOG_DIR"/*.log > /dev/null 2>&1; then
    ls -lh "$LOG_DIR"/*.log | awk '{print "  " $9 " - " $5}'
else
    echo "  没有日志文件"
fi
echo ""

# 统计错误
echo "⚠️  错误统计:"
for log in "$LOG_DIR"/*.log; do
    if [ -f "$log" ]; then
        filename=$(basename "$log")
        error_count=$(grep -ic "error" "$log" 2>/dev/null || echo "0")
        if [ "$error_count" -gt 0 ]; then
            echo "  ❌ $filename: $error_count 个错误"
        else
            echo "  ✅ $filename: 无错误"
        fi
    fi
done
echo ""

# 最近的错误
echo "🔍 最近10条错误（如果有）:"
if grep -iH "error" "$LOG_DIR"/*.log 2>/dev/null | tail -10 > /tmp/recent_errors.txt; then
    if [ -s /tmp/recent_errors.txt ]; then
        cat /tmp/recent_errors.txt
    else
        echo "  ✅ 没有发现错误"
    fi
else
    echo "  ✅ 没有发现错误"
fi
echo ""

echo "========================================"
echo "💡 使用方法:"
echo ""
echo "  查看实时日志（所有服务）:"
echo "    tail -f $LOG_DIR/*.log"
echo ""
echo "  查看单个服务日志:"
echo "    tail -f $LOG_DIR/backend.log"
echo "    tail -f $LOG_DIR/rag.log"
echo "    tail -f $LOG_DIR/llm.log"
echo "    tail -f $LOG_DIR/edge_tts.log"
echo "    tail -f $LOG_DIR/avatar_manager.log"
echo "    tail -f $LOG_DIR/frontend.log"
echo ""
echo "  搜索错误:"
echo "    grep -i 'error' $LOG_DIR/*.log"
echo ""
echo "  清理日志:"
echo "    ./clear_logs.sh"
echo ""
echo "========================================"

# 清理临时文件
rm -f /tmp/recent_errors.txt






