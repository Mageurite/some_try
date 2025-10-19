#!/bin/bash

echo "=========================================="
echo "验证 Avatar 音频修复"
echo "=========================================="
echo

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "【步骤 1】检查 TTS 服务（端口 8604）..."
if netstat -tln 2>/dev/null | grep ":8604 " > /dev/null 2>&1; then
    echo -e "${GREEN}✅ TTS 端口正在监听${NC}"
    
    # 测试健康检查
    if curl -sf http://localhost:8604/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ TTS 服务响应正常${NC}"
        HEALTH_RESPONSE=$(curl -s http://localhost:8604/health)
        echo "   响应: $HEALTH_RESPONSE"
    else
        echo -e "${RED}❌ TTS 服务无响应${NC}"
        echo "   请检查日志: tail -f logs/edge_tts.log"
    fi
else
    echo -e "${RED}❌ TTS 端口未监听${NC}"
    echo
    echo "尝试启动 TTS 服务..."
    cd tts/edge
    source /workspace/conda/etc/profile.d/conda.sh
    conda activate edge
    nohup python server.py --model_name edgeTTS --port 8604 --use_gpu false > ../../logs/edge_tts.log 2>&1 &
    echo "   服务已启动，PID: $!"
    echo "   等待 10 秒让服务完全启动..."
    sleep 10
    
    # 重新检查
    if curl -sf http://localhost:8604/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ TTS 服务现在正常运行${NC}"
    else
        echo -e "${RED}❌ TTS 服务启动失败${NC}"
        echo "   查看日志: tail -f logs/edge_tts.log"
        exit 1
    fi
    cd ../..
fi
echo

echo "【步骤 2】检查 Avatar 服务（端口 8615）..."
if netstat -tln 2>/dev/null | grep ":8615 " > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Avatar 服务端口正在监听${NC}"
    
    # 检查进程
    AVATAR_PID=$(ps aux | grep "app.py.*8615" | grep -v grep | awk '{print $2}' | head -1)
    if [ -n "$AVATAR_PID" ]; then
        echo -e "${GREEN}✅ Avatar 进程运行中 (PID: $AVATAR_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  未找到 Avatar 进程${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Avatar 服务未运行${NC}"
    echo "   请先启动 Avatar："
    echo "   curl -X POST 'http://localhost:8606/switch_avatar?avatar_id=yongen&ref_file=ref_audio/silence.wav'"
fi
echo

echo "【步骤 3】检查 Avatar 管理服务（端口 8606）..."
if netstat -tln 2>/dev/null | grep ":8606 " > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Avatar 管理服务端口正在监听${NC}"
    
    # 测试 API
    if curl -sf http://localhost:8606/avatar/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 管理服务 API 响应正常${NC}"
        
        # 显示当前 Avatar 状态
        STATUS=$(curl -s http://localhost:8606/avatar/status)
        echo "   当前状态:"
        echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
    else
        echo -e "${YELLOW}⚠️  管理服务 API 无响应${NC}"
    fi
else
    echo -e "${RED}❌ Avatar 管理服务未运行${NC}"
    echo "   请运行: cd lip-sync && python live_server.py"
fi
echo

echo "【步骤 4】检查前端服务（端口 3000）..."
if netstat -tln 2>/dev/null | grep ":3000 " > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务正在运行${NC}"
else
    echo -e "${YELLOW}⚠️  前端服务未运行${NC}"
    echo "   请运行: cd frontend && npm start"
fi
echo

echo "【步骤 5】验证 TTS 连接（从 Avatar 日志）..."
if tail -100 logs/avatar_manager.log 2>/dev/null | grep -q "Connection refused.*8604"; then
    echo -e "${RED}❌ Avatar 仍无法连接到 TTS 服务${NC}"
    echo "   最近的连接错误:"
    tail -100 logs/avatar_manager.log | grep "Connection refused.*8604" | tail -3
    echo
    echo "   建议："
    echo "   1. 重启 Avatar 服务"
    echo "   2. 检查 TTS 日志: tail -f logs/edge_tts.log"
elif tail -50 logs/avatar_manager.log 2>/dev/null | grep -q "ERROR.*tts\|ERROR.*cosyvoice"; then
    echo -e "${YELLOW}⚠️  发现 TTS 相关错误${NC}"
    echo "   最近的 TTS 错误:"
    tail -50 logs/avatar_manager.log | grep -i "error.*tts\|error.*cosyvoice" | tail -3
else
    echo -e "${GREEN}✅ 未发现 TTS 连接错误${NC}"
fi
echo

echo "=========================================="
echo "总结"
echo "=========================================="

# 统计
CHECKS_PASSED=0
CHECKS_TOTAL=5

netstat -tln 2>/dev/null | grep -q ":8604 " && ((CHECKS_PASSED++))
netstat -tln 2>/dev/null | grep -q ":8615 " && ((CHECKS_PASSED++))
netstat -tln 2>/dev/null | grep -q ":8606 " && ((CHECKS_PASSED++))
netstat -tln 2>/dev/null | grep -q ":3000 " && ((CHECKS_PASSED++))
curl -sf http://localhost:8604/health > /dev/null 2>&1 && ((CHECKS_PASSED++))

echo "通过检查: $CHECKS_PASSED / $CHECKS_TOTAL"
echo

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}🎉 所有检查通过！音频应该能正常工作了${NC}"
    echo
    echo "📝 使用步骤："
    echo "1. 打开浏览器: http://localhost:3000"
    echo "2. 选择一个 Avatar"
    echo "3. 点击视频右下角的播放按钮（▶）"
    echo "4. 发送消息测试音频"
    echo
    echo "如果还是没有声音，请检查："
    echo "- 浏览器控制台（F12）是否有错误"
    echo "- 浏览器音量是否开启"
    echo "- 系统音量是否开启"
    echo "- 浏览器是否允许自动播放音频"
elif [ $CHECKS_PASSED -ge 3 ]; then
    echo -e "${YELLOW}⚠️  部分服务正常，但可能需要额外配置${NC}"
    echo
    echo "建议："
    echo "1. 查看上面标记为 ❌ 或 ⚠️  的项目"
    echo "2. 按照提示启动缺失的服务"
    echo "3. 重新运行此脚本验证"
else
    echo -e "${RED}❌ 多个服务未运行，请先启动所有服务${NC}"
    echo
    echo "快速启动："
    echo "   ./start_all.sh"
    echo
    echo "或手动启动："
    echo "   cd tts/edge && python server.py --port 8604 &"
    echo "   cd lip-sync && python live_server.py &"
    echo "   cd frontend && npm start &"
fi
echo

echo "📚 更多信息："
echo "   - 问题解决文档: 解决视频无声音问题.md"
echo "   - 日志查看: tail -f logs/avatar_manager.log"
echo "   - 日志查看: tail -f logs/edge_tts.log"

