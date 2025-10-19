#!/bin/bash

echo "========================================"
echo "Avatar WebRTC 连接测试脚本"
echo "========================================"
echo

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试1: 检查Avatar服务
echo "【测试1】检查Avatar服务..."
if ps aux | grep "app.py.*avatar.*8615" | grep -v grep > /dev/null; then
    echo -e "${GREEN}✅ Avatar服务正在运行${NC}"
    ps aux | grep "app.py.*avatar.*8615" | grep -v grep | head -1
else
    echo -e "${RED}❌ Avatar服务未运行${NC}"
    echo "   请使用以下命令启动:"
    echo "   python test_switch.py yongen"
    exit 1
fi
echo

# 测试2: 检查端口监听
echo "【测试2】检查端口8615监听状态..."
if netstat -tln | grep ":8615 " > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 端口8615正在监听${NC}"
    netstat -tln | grep ":8615 "
else
    echo -e "${RED}❌ 端口8615未监听${NC}"
    exit 1
fi
echo

# 测试3: 测试HTTP连接
echo "【测试3】测试HTTP连接..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8615/webrtcapi.html)
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ webrtcapi.html可以访问 (HTTP $HTTP_STATUS)${NC}"
else
    echo -e "${RED}❌ webrtcapi.html无法访问 (HTTP $HTTP_STATUS)${NC}"
    exit 1
fi
echo

# 测试4: 检查TTS服务
echo "【测试4】检查TTS服务..."
if ps aux | grep "server.py.*8604" | grep -v grep > /dev/null; then
    echo -e "${GREEN}✅ TTS服务正在运行${NC}"
else
    echo -e "${YELLOW}⚠️  TTS服务未运行（不影响视频加载）${NC}"
fi
echo

# 测试5: 检查Avatar文件
echo "【测试5】检查Avatar文件完整性..."
CURRENT_AVATAR=$(ps aux | grep "app.py.*avatar" | grep -v grep | grep -oP "avatar_id \K\w+" | head -1)
if [ -z "$CURRENT_AVATAR" ]; then
    echo -e "${YELLOW}⚠️  无法确定当前Avatar ID${NC}"
else
    echo "当前Avatar: $CURRENT_AVATAR"
    if [ -d "data/avatars/$CURRENT_AVATAR" ]; then
        echo -e "${GREEN}✅ Avatar目录存在${NC}"
        IMG_COUNT=$(ls data/avatars/$CURRENT_AVATAR/full_imgs/*.png 2>/dev/null | wc -l)
        echo "   图片数量: $IMG_COUNT"
        if [ $IMG_COUNT -gt 0 ]; then
            echo -e "${GREEN}✅ Avatar图片完整${NC}"
        else
            echo -e "${RED}❌ Avatar图片缺失${NC}"
        fi
    else
        echo -e "${RED}❌ Avatar目录不存在${NC}"
    fi
fi
echo

# 测试6: 检查日志中的错误
echo "【测试6】检查最近的错误日志..."
if [ -f "livetalking.log" ]; then
    ERROR_COUNT=$(tail -100 livetalking.log | grep -iE "error|exception|fail" | grep -v "Fail" | wc -l)
    if [ $ERROR_COUNT -eq 0 ]; then
        echo -e "${GREEN}✅ 最近100行日志中无错误${NC}"
    else
        echo -e "${YELLOW}⚠️  发现 $ERROR_COUNT 条错误信息${NC}"
        echo "   最近的错误:"
        tail -100 livetalking.log | grep -iE "error|exception" | tail -5
    fi
else
    echo -e "${YELLOW}⚠️  日志文件不存在${NC}"
fi
echo

# 测试7: 网络连接测试
echo "【测试7】测试网络连接..."
if curl -s --max-time 3 http://stun.l.google.com:19302 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 可以连接到STUN服务器${NC}"
else
    echo -e "${YELLOW}⚠️  无法连接到Google STUN服务器（可能影响WebRTC）${NC}"
fi
echo

# 总结
echo "========================================"
echo "测试完成！"
echo "========================================"
echo
echo "访问地址:"
echo "  本机: http://localhost:8615/webrtcapi.html"
echo "  远程: http://服务器IP:8615/webrtcapi.html"
echo
echo "如果仍然无法访问，请检查:"
echo "  1. 浏览器控制台错误 (F12 -> Console)"
echo "  2. 使用Chrome或Firefox浏览器"
echo "  3. 确保是localhost访问或使用端口转发"
echo "  4. 防火墙设置"
echo
echo "需要帮助？提供以下信息:"
echo "  - 访问方式（本机/远程）"
echo "  - 浏览器类型和版本"
echo "  - 浏览器控制台的错误信息"
echo "========================================"






