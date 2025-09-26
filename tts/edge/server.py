import io
import time
import asyncio
import edge_tts
from fastapi import FastAPI, Form, HTTPException
from fastapi.responses import Response
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from pydub import AudioSegment
import uvicorn

import sys

print(f">>> Python executable: {sys.executable}\n")

app = FastAPI()


async def generate_edge_tts(text: str, voice: str = "en-US-GuyNeural") -> bytes:
    communicate = edge_tts.Communicate(text, voice)
    out_buf = io.BytesIO()

    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            out_buf.write(chunk["data"])

    return out_buf.getvalue()


@app.post("/generate")
async def tts_generate(
        tts_text: str = Form(...),
        prompt_text: str = Form("en-US-GuyNeural"),
        prompt_wav: UploadFile = File(...)
):
    try:
        start_time = time.time()
        print(f">>> Generating TTS for: [{tts_text}] with voice: {prompt_text}")
        audio_bytes = await generate_edge_tts(tts_text, prompt_text)
        end_time = time.time()

        # 计算音频持续时间（单位：秒）
        audio = AudioSegment.from_file(io.BytesIO(audio_bytes), format="mp3")
        duration = len(audio) / 1000

        # 计算 RTF（实时系数）
        rtf = (end_time - start_time) / duration
        print(f">>> RTF: {rtf:.4f} (Real-Time Factor)")

        # 额外转换成 wav：
        wav_buf = io.BytesIO()
        audio.export(wav_buf, format="wav")
        return Response(content=wav_buf.getvalue(), media_type="audio/wav")

        # 可选保存临时文件
        with open("temp_edge_output.mp3", "wb") as f:
            f.write(audio_bytes)
        print(">>> Saved to temp_edge_output.mp3")

        return Response(content=audio_bytes, media_type="audio/mpeg")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS generation failed: {e}")


@app.get("/health")
def health():
    return {"status": "running"}


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--model_name', required=True)
    parser.add_argument('--port', type=int, default=5033)
    parser.add_argument('--use_gpu', type=bool, default=False)
    args = parser.parse_args()

    if args.model_name == 'edgeTTS':
        print(">>> Using Edge TTS model")
    else:
        raise ValueError("nsupported model name: {args.model_name}, only 'edgeTTS' is supported.")

    if args.use_gpu:
        print(">>> Edge TTS does not support GPU, Use CPU for inference.")

    uvicorn.run(app, host="0.0.0.0", port=args.port)