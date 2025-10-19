#!/usr/bin/env python3
"""
简化版延迟测试脚本
仅测试LLM的First Token延迟，不需要WebRTC依赖
"""

import time
import json
import requests
from datetime import datetime

def print_header(title):
    """打印测试标题"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def print_result(name, value, unit="ms"):
    """打印测试结果"""
    if unit == "ms":
        print(f"  ✅ {name}: {value*1000:.2f} {unit}")
    else:
        print(f"  ✅ {name}: {value:.4f} {unit}")

def test_llm_first_token_latency(test_text="Hello, how are you?", llm_url="http://localhost:8610/chat/stream"):
    """测试LLM的First Token延迟"""
    print_header("LLM First Token延迟测试")
    
    try:
        print(f"  📝 测试文本: '{test_text}'")
        print(f"  🔗 LLM服务: {llm_url}")
        
        # 记录开始时间
        start_time = time.time()
        
        # 发送请求
        response = requests.post(
            llm_url,
            json={
                "input": test_text,
                "session_id": 999999,
                "user_id": 1
            },
            stream=True,
            timeout=60
        )
        
        request_sent_time = time.time()
        
        if response.status_code != 200:
            raise Exception(f"LLM服务返回错误: {response.status_code}")
        
        print(f"  ⏳ 等待响应...\n")
        
        # 读取流式响应
        first_chunk_time = None
        last_chunk_time = None
        chunk_count = 0
        total_chars = 0
        chunks = []
        
        for line in response.iter_lines(decode_unicode=True):
            current_time = time.time()
            
            if line and line.startswith("data:"):
                chunk_count += 1
                chunk_data = json.loads(line.replace("data: ", ""))
                chunk_text = chunk_data.get("chunk", "")
                
                if chunk_text:
                    total_chars += len(chunk_text)
                    chunks.append(chunk_text)
                
                # 记录第一个chunk时间
                if first_chunk_time is None and chunk_text:
                    first_chunk_time = current_time
                    first_token_latency = first_chunk_time - start_time
                    print(f"  ⚡ First Token延迟:")
                    print_result("总延迟", first_token_latency)
                    print_result("网络+处理", first_chunk_time - request_sent_time)
                    print(f"  📊 首个chunk内容: '{chunk_text[:50]}{'...' if len(chunk_text) > 50 else ''}'")
                    print()
                
                # 检查是否完成
                if chunk_data.get("status") == "finished":
                    last_chunk_time = current_time
                    break
        
        if first_chunk_time is None:
            raise Exception("没有收到任何响应chunk")
        
        total_latency = last_chunk_time - start_time if last_chunk_time else time.time() - start_time
        generation_time = last_chunk_time - first_chunk_time if last_chunk_time else 0
        
        print(f"  📊 完整响应统计:")
        print(f"  - 总chunk数: {chunk_count}")
        print(f"  - 总字符数: {total_chars}")
        print_result("总响应时间", total_latency)
        if generation_time > 0:
            print_result("生成阶段", generation_time)
            print(f"  - 生成速度: {total_chars/generation_time:.2f} 字符/秒")
        
        print(f"\n  💬 完整响应预览:")
        full_response = "".join(chunks)
        preview_length = min(300, len(full_response))
        print(f"  {full_response[:preview_length]}{'...' if len(full_response) > preview_length else ''}")
        
        # 返回结果
        return {
            'success': True,
            'first_token_latency': first_token_latency if first_chunk_time else None,
            'total_latency': total_latency,
            'chunk_count': chunk_count,
            'total_chars': total_chars,
            'generation_speed': total_chars/generation_time if generation_time > 0 else 0,
            'full_response': full_response
        }
        
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return {'success': False, 'error': str(e)}

def test_avatar_service_health():
    """测试数字人服务健康状态"""
    print_header("数字人服务健康检查")
    
    services = [
        ("Lip-sync服务", "http://localhost:8615/offer", "POST"),
        ("LLM服务", "http://localhost:8610/chat/stream", "POST"),
        ("Backend服务", "http://localhost:8203/api/chat/history", "GET"),
    ]
    
    results = {}
    
    for name, url, method in services:
        try:
            start = time.time()
            if method == "GET":
                resp = requests.get(url, timeout=5)
            else:
                resp = requests.post(url, json={}, timeout=5)
            latency = time.time() - start
            
            # 即使返回错误状态码，只要能连接就算服务在线
            status = "✅ 在线" if resp.status_code < 500 else "⚠️  服务错误"
            print(f"  {status} - {name}")
            print(f"      URL: {url}")
            print(f"      响应时间: {latency*1000:.2f} ms")
            print(f"      状态码: {resp.status_code}")
            results[name] = {'online': True, 'latency': latency, 'status_code': resp.status_code}
        except requests.exceptions.ConnectionError:
            print(f"  ❌ 离线 - {name}")
            print(f"      URL: {url}")
            print(f"      错误: 无法连接")
            results[name] = {'online': False, 'error': 'Connection refused'}
        except Exception as e:
            print(f"  ❌ 错误 - {name}")
            print(f"      URL: {url}")
            print(f"      错误: {e}")
            results[name] = {'online': False, 'error': str(e)}
    
    return results

def main():
    """主测试函数"""
    print("\n🚀 数字人系统延迟测试工具（简化版）\n")
    
    # 1. 服务健康检查
    health_results = test_avatar_service_health()
    
    # 2. First Token延迟测试
    print("\n")
    test_questions = [
        "What is machine learning?",
        "Explain quantum computing in simple terms.",
        "Hello, how are you today?"
    ]
    
    print_header("选择测试场景")
    print("\n  可用的测试问题:")
    for i, q in enumerate(test_questions, 1):
        print(f"    {i}. {q}")
    print(f"    {len(test_questions)+1}. 自定义问题")
    
    choice = input(f"\n  请选择 (1-{len(test_questions)+1}) [默认: 1]: ").strip()
    
    if not choice:
        choice = "1"
    
    if choice.isdigit() and 1 <= int(choice) <= len(test_questions):
        test_text = test_questions[int(choice)-1]
    elif choice == str(len(test_questions)+1):
        test_text = input("  请输入测试问题: ").strip()
        if not test_text:
            test_text = test_questions[0]
    else:
        print("  无效选择，使用默认问题")
        test_text = test_questions[0]
    
    print("\n")
    result = test_llm_first_token_latency(test_text)
    
    # 3. 保存结果
    if result.get('success'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"latency_test_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump({
                'timestamp': datetime.now().isoformat(),
                'test_question': test_text,
                'health_check': health_results,
                'latency_results': result
            }, f, indent=2, ensure_ascii=False)
        
        print_header("测试完成")
        print(f"\n  💾 结果已保存到: {filename}")
        print(f"  ⚡ First Token延迟: {result['first_token_latency']*1000:.2f} ms")
        print(f"  📊 生成速度: {result['generation_speed']:.2f} 字符/秒")
        print("\n" + "="*60 + "\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  测试被用户中断")
    except Exception as e:
        print(f"\n\n❌ 测试过程中发生错误: {e}")
        import traceback
        traceback.print_exc()

