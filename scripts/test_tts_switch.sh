#!/bin/bash
#
# 测试TTS自动切换功能
#

PROJECT_ROOT="/workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2"
cd "${PROJECT_ROOT}/lip-sync"

source /workspace/conda/etc/profile.d/conda.sh
conda activate avatar

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              测试TTS自动切换功能                                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# 列出所有可用的Avatars
echo "📋 可用的Avatars:"
if [ -d "data/avatars" ]; then
    for avatar in data/avatars/*/; do
        avatar_name=$(basename "$avatar")
        if [ -f "$avatar/config.json" ]; then
            tts_model=$(grep -oP '"tts_model":\s*"\K[^"]+' "$avatar/config.json" 2>/dev/null || echo "未指定")
            echo "   - $avatar_name (TTS: $tts_model) ✅配置"
        else
            echo "   - $avatar_name (无config.json)"
        fi
    done
else
    echo "   ⚠️  未找到avatars目录"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""

# 测试读取Avatar配置
echo "🧪 测试1: 读取Avatar TTS配置"
echo ""
echo "请输入要测试的Avatar ID (例如: test_yongen): "
read -r AVATAR_ID

if [ -z "$AVATAR_ID" ]; then
    echo "⚠️  未提供Avatar ID，使用默认: test_yongen"
    AVATAR_ID="test_yongen"
fi

echo ""
echo "正在测试Avatar: $AVATAR_ID"
echo ""

# 运行TTS配置管理器测试
python tts_config_manager.py "$AVATAR_ID"

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""

# 检查当前TTS服务状态
echo "🔍 检查当前TTS服务状态 (端口8604):"
if lsof -i :8604 > /dev/null 2>&1; then
    echo "   ✅ TTS服务正在运行"
    TTS_PID=$(lsof -t -i :8604)
    echo "   PID: $TTS_PID"
    
    # 尝试检测TTS类型
    TTS_CMD=$(ps -p "$TTS_PID" -o cmd= | head -1)
    if [[ "$TTS_CMD" == *"edge"* ]]; then
        echo "   类型: Edge TTS"
    elif [[ "$TTS_CMD" == *"sovits"* ]]; then
        echo "   类型: Sovits"
    elif [[ "$TTS_CMD" == *"cosyvoice"* ]]; then
        echo "   类型: CosyVoice"
    elif [[ "$TTS_CMD" == *"taco"* ]]; then
        echo "   类型: Tacotron"
    else
        echo "   类型: 未知"
    fi
else
    echo "   ⚠️  TTS服务未运行"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "✅ 测试完成!"
echo ""
echo "📖 说明:"
echo "   1. 如果Avatar有config.json，会显示配置的TTS模型"
echo "   2. switch_avatar API会自动切换到正确的TTS服务"
echo "   3. 学生端选择Avatar时，TTS会自动匹配教师创建时的设置"
echo ""






