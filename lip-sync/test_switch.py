#!/usr/bin/env python3
"""
Avatar 切换测试脚本
使用方法: python test_switch.py <avatar_id>
例如: python test_switch.py g
"""

import requests
import sys

def switch_avatar(avatar_id, server_url="http://0.0.0.0:8606"):
    """切换到指定的avatar"""
    
    # API endpoint
    url = f"{server_url}/switch_avatar"
    
    # 参数
    params = {
        "avatar_id": avatar_id,
        "ref_file": "ref_audio/complete_silence.wav"  # 默认参考音频（完全静音）
    }
    
    print(f"\n{'='*60}")
    print(f"正在切换到 Avatar: {avatar_id}")
    print(f"服务器: {server_url}")
    print(f"参数: {params}")
    print(f"{'='*60}\n")
    
    try:
        # 发送POST请求
        print("发送请求...")
        response = requests.post(url, params=params, timeout=120)
        
        print(f"状态码: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"\n响应内容: {result}")
            
            if result.get("status") == "success":
                print(f"\n✓ 成功切换到 Avatar: {avatar_id}")
                print(f"✓ {result.get('message')}")
                return True
            else:
                print(f"\n✗ 切换失败: {result.get('message')}")
                return False
        elif response.status_code == 400:
            error = response.json()
            print(f"\n✗ 请求错误: {error.get('detail')}")
            return False
        else:
            print(f"\n✗ 请求失败: {response.text}")
            return False
            
    except requests.Timeout:
        print("\n✗ 请求超时，服务可能启动时间较长，请稍后检查")
        return False
    except Exception as e:
        print(f"\n✗ 发生错误: {e}")
        return False

def list_avatars(server_url="http://0.0.0.0:8606"):
    """列出所有可用的avatars"""
    url = f"{server_url}/avatar/get_avatars"
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            result = response.json()
            avatars = result.get("avatars", [])
            print(f"\n可用的 Avatars:")
            for avatar in avatars:
                print(f"  - {avatar}")
            return avatars
        else:
            print(f"无法获取avatar列表: {response.text}")
            return []
    except Exception as e:
        print(f"获取avatar列表时出错: {e}")
        return []

if __name__ == "__main__":
    # 首先列出所有可用的avatars
    avatars = list_avatars()
    
    if len(sys.argv) < 2:
        print(f"\n使用方法: python {sys.argv[0]} <avatar_id>")
        print(f"可用的 avatars: {', '.join(avatars)}")
        print(f"\n示例:")
        for avatar in avatars:
            print(f"  python {sys.argv[0]} {avatar}")
        sys.exit(1)
    
    avatar_id = sys.argv[1]
    
    # 切换avatar
    success = switch_avatar(avatar_id)
    
    sys.exit(0 if success else 1)






