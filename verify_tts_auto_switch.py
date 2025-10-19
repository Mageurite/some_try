#!/usr/bin/env python3
"""
TTS自动切换系统验证脚本
测试所有组件是否正确实现
"""

import os
import sys
import json
import requests
import subprocess
from pathlib import Path

PROJECT_ROOT = Path("/workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2")
LIPSYNC_DIR = PROJECT_ROOT / "lip-sync"
AVATARS_DIR = LIPSYNC_DIR / "data" / "avatars"

class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text:^70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.END}\n")

def print_success(text):
    print(f"{Colors.GREEN}✅ {text}{Colors.END}")

def print_warning(text):
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.END}")

def print_error(text):
    print(f"{Colors.RED}❌ {text}{Colors.END}")

def print_info(text):
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.END}")

def check_file_exists(filepath, description):
    """检查文件是否存在"""
    if os.path.exists(filepath):
        print_success(f"{description}: {filepath}")
        return True
    else:
        print_error(f"{description}不存在: {filepath}")
        return False

def check_tts_manager():
    """检查TTS配置管理器"""
    print_header("测试1: TTS配置管理器")
    
    tts_manager_path = LIPSYNC_DIR / "tts_config_manager.py"
    if not check_file_exists(tts_manager_path, "TTS配置管理器"):
        return False
    
    # 检查关键类和方法
    with open(tts_manager_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    required_items = [
        ("class TTSConfigManager", "TTSConfigManager类"),
        ("def load_avatar_config", "load_avatar_config方法"),
        ("def get_current_tts", "get_current_tts方法"),
        ("def stop_tts_service", "stop_tts_service方法"),
        ("def start_tts_service", "start_tts_service方法"),
        ("def ensure_correct_tts", "ensure_correct_tts方法"),
        ("def get_avatar_tts_info", "get_avatar_tts_info方法"),
    ]
    
    all_found = True
    for item, desc in required_items:
        if item in content:
            print_success(f"找到{desc}")
        else:
            print_error(f"未找到{desc}")
            all_found = False
    
    return all_found

def check_live_server_modifications():
    """检查live_server.py的修改"""
    print_header("测试2: Avatar管理服务修改")
    
    live_server_path = LIPSYNC_DIR / "live_server.py"
    if not check_file_exists(live_server_path, "Avatar管理服务"):
        return False
    
    with open(live_server_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 检查/avatar/add的修改
    print_info("检查 /avatar/add 端点修改...")
    if "avatar_config = {" in content and '"tts_model"' in content:
        print_success("找到Avatar配置保存逻辑")
        has_add = True
    else:
        print_error("未找到Avatar配置保存逻辑")
        has_add = False
    
    # 检查/switch_avatar的修改
    print_info("检查 /switch_avatar 端点修改...")
    if "from tts_config_manager import get_tts_manager" in content:
        print_success("找到TTS配置管理器导入")
        has_switch = True
    else:
        print_error("未找到TTS配置管理器导入")
        has_switch = False
    
    if "ensure_correct_tts" in content:
        print_success("找到TTS切换调用")
    else:
        print_error("未找到TTS切换调用")
        has_switch = False
    
    return has_add and has_switch

def check_app_modifications():
    """检查app.py的修改"""
    print_header("测试3: Lip-sync服务修改")
    
    app_path = LIPSYNC_DIR / "app.py"
    if not check_file_exists(app_path, "Lip-sync服务"):
        return False
    
    with open(app_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "from tts_config_manager import get_tts_manager" in content:
        print_success("找到TTS配置管理器导入")
    else:
        print_warning("未找到TTS配置管理器导入（可选功能）")
    
    if "get_avatar_tts_info" in content:
        print_success("找到TTS信息获取调用")
    else:
        print_warning("未找到TTS信息获取调用（可选功能）")
    
    return True

def check_avatar_configs():
    """检查现有Avatar的配置"""
    print_header("测试4: Avatar配置文件")
    
    if not os.path.exists(AVATARS_DIR):
        print_error(f"Avatars目录不存在: {AVATARS_DIR}")
        return False
    
    avatars = [d for d in os.listdir(AVATARS_DIR) if os.path.isdir(AVATARS_DIR / d)]
    
    if not avatars:
        print_warning("未找到任何Avatar")
        return True
    
    print_info(f"找到 {len(avatars)} 个Avatar:")
    
    has_config = 0
    for avatar in avatars:
        config_path = AVATARS_DIR / avatar / "config.json"
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                
                tts_model = config.get('tts_model', '未指定')
                print_success(f"  {avatar}: TTS模型={tts_model}")
                
                # 验证配置完整性
                required_fields = ['avatar_id', 'tts_model', 'avatar_model']
                missing_fields = [f for f in required_fields if f not in config]
                if missing_fields:
                    print_warning(f"    缺少字段: {', '.join(missing_fields)}")
                
                has_config += 1
            except Exception as e:
                print_error(f"  {avatar}: 配置文件解析失败 - {e}")
        else:
            print_warning(f"  {avatar}: 无config.json（旧Avatar）")
    
    print_info(f"\n总结: {has_config}/{len(avatars)} 个Avatar有配置文件")
    return True

def check_tts_services():
    """检查TTS服务配置"""
    print_header("测试5: TTS服务配置")
    
    tts_dirs = {
        "Edge TTS": PROJECT_ROOT / "tts" / "edge" / "server.py",
        "Sovits": PROJECT_ROOT / "tts" / "sovits" / "GPT-SoVITS" / "so_server.py",
        "CosyVoice": PROJECT_ROOT / "tts" / "cosyvoice" / "CosyVoice" / "server.py",
        "Tacotron": PROJECT_ROOT / "tts" / "taco" / "taco_server.py",
    }
    
    available = 0
    for name, path in tts_dirs.items():
        if os.path.exists(path):
            print_success(f"{name}: {path}")
            available += 1
        else:
            print_warning(f"{name}: 未找到 ({path})")
    
    print_info(f"\n可用TTS服务: {available}/{len(tts_dirs)}")
    return available > 0

def check_service_status():
    """检查当前运行的服务"""
    print_header("测试6: 服务运行状态")
    
    services = {
        8606: "Avatar管理服务",
        8604: "TTS服务",
        8615: "Lip-sync服务",
    }
    
    for port, name in services.items():
        try:
            result = subprocess.run(
                ["lsof", "-i", f":{port}"],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                print_success(f"{name} (端口{port}): 运行中")
            else:
                print_warning(f"{name} (端口{port}): 未运行")
        except Exception as e:
            print_error(f"检查端口{port}失败: {e}")
    
    return True

def test_tts_manager_import():
    """测试TTS管理器导入"""
    print_header("测试7: TTS管理器功能测试")
    
    sys.path.insert(0, str(LIPSYNC_DIR))
    
    try:
        from tts_config_manager import get_tts_manager, TTSConfigManager
        print_success("成功导入TTS配置管理器")
        
        # 创建管理器实例
        manager = get_tts_manager()
        print_success("成功创建管理器实例")
        
        # 测试列出TTS命令
        tts_commands = manager.tts_commands
        print_info(f"支持的TTS模型: {', '.join(tts_commands.keys())}")
        
        # 如果有Avatar，测试读取配置
        if os.path.exists(AVATARS_DIR):
            avatars = [d for d in os.listdir(AVATARS_DIR) if os.path.isdir(AVATARS_DIR / d)]
            if avatars:
                test_avatar = avatars[0]
                print_info(f"测试读取Avatar配置: {test_avatar}")
                
                config = manager.load_avatar_config(test_avatar)
                if config:
                    print_success(f"成功读取配置: {json.dumps(config, indent=2, ensure_ascii=False)}")
                else:
                    print_warning(f"Avatar {test_avatar} 无配置文件（这是正常的，如果是旧Avatar）")
                
                # 获取TTS信息
                tts_info = manager.get_avatar_tts_info(test_avatar)
                print_info(f"TTS信息: {json.dumps(tts_info, indent=2, ensure_ascii=False)}")
        
        return True
        
    except ImportError as e:
        print_error(f"导入失败: {e}")
        return False
    except Exception as e:
        print_error(f"测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """主测试函数"""
    print(f"\n{Colors.BOLD}TTS自动切换系统验证{Colors.END}")
    print(f"{Colors.BOLD}项目路径: {PROJECT_ROOT}{Colors.END}\n")
    
    results = []
    
    # 运行所有测试
    results.append(("TTS配置管理器", check_tts_manager()))
    results.append(("Avatar管理服务修改", check_live_server_modifications()))
    results.append(("Lip-sync服务修改", check_app_modifications()))
    results.append(("Avatar配置文件", check_avatar_configs()))
    results.append(("TTS服务配置", check_tts_services()))
    results.append(("服务运行状态", check_service_status()))
    results.append(("TTS管理器功能", test_tts_manager_import()))
    
    # 汇总结果
    print_header("测试结果汇总")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        if result:
            print_success(f"{name}: 通过")
        else:
            print_error(f"{name}: 失败")
    
    print()
    if passed == total:
        print_success(f"所有测试通过! ({passed}/{total})")
        print_info("\n系统已准备就绪！")
        print_info("下一步:")
        print_info("  1. 启动所有服务: ./start_all.sh")
        print_info("  2. 教师端创建Avatar时会自动保存TTS配置")
        print_info("  3. 学生端选择Avatar时会自动切换TTS服务")
        return 0
    else:
        print_warning(f"部分测试失败: {passed}/{total} 通过")
        print_info("\n请检查失败的测试并修复问题")
        return 1

if __name__ == "__main__":
    sys.exit(main())






