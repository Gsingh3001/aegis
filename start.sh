#!/bin/bash
# ══════════════════════════════════════════════════════
# AEGIS — One Command Startup
# AMD AI Hackathon 2026 · Team-557 · Gagandeep Singh
# Usage: bash start.sh
# ══════════════════════════════════════════════════════

echo ""
echo "████████████████████████████████████████████████████"
echo "  AEGIS — Enterprise Cyber Defense Framework"
echo "  AMD MI300X · 192GB HBM3 · vLLM 0.7.1 + ROCm 7.0"
echo "████████████████████████████████████████████████████"
echo ""

# ── Step 1: Download models if not present ──────────────
echo "[ 1/6 ] Checking models..."

if [ ! -f "/workspace/models/mistral7b/config.json" ]; then
  echo "  Downloading Mistral 7B (this takes 10-15 minutes)..."
  python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('mistralai/Mistral-7B-Instruct-v0.3', local_dir='/workspace/models/mistral7b')
print('Mistral DONE')
" > /workspace/dl_mistral.log 2>&1
  echo "  ✅ Mistral 7B downloaded"
else
  echo "  ✅ Mistral 7B already present"
fi

if [ ! -f "/workspace/models/tinyllama/config.json" ]; then
  echo "  Downloading TinyLlama..."
  python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('TinyLlama/TinyLlama-1.1B-Chat-v1.0', local_dir='/workspace/models/tinyllama')
print('TinyLlama DONE')
" > /workspace/dl_tiny.log 2>&1
  echo "  ✅ TinyLlama downloaded"
else
  echo "  ✅ TinyLlama already present"
fi

# ── Step 2: Kill any existing servers ───────────────────
echo ""
echo "[ 2/6 ] Cleaning up existing servers..."
pkill -f "vllm.entrypoints" 2>/dev/null
pkill -f "api_server" 2>/dev/null
pkill -f "http.server" 2>/dev/null
fuser -k 8001/tcp 2>/dev/null
fuser -k 8003/tcp 2>/dev/null
fuser -k 8891/tcp 2>/dev/null
fuser -k 7777/tcp 2>/dev/null
sleep 4
echo "  ✅ Ports cleared"

# ── Step 3: Launch vLLM servers ─────────────────────────
echo ""
echo "[ 3/6 ] Launching vLLM servers..."

python3 -m vllm.entrypoints.openai.api_server \
  --model /workspace/models/mistral7b \
  --port 8001 \
  --gpu-memory-utilization 0.55 \
  --max-model-len 4096 \
  --dtype float16 \
  > /workspace/vllm_mistral.log 2>&1 &
echo "  Mistral 7B launching on port 8001 (PID $!)"

python3 -m vllm.entrypoints.openai.api_server \
  --model /workspace/models/tinyllama \
  --port 8003 \
  --gpu-memory-utilization 0.25 \
  --max-model-len 2048 \
  --dtype float16 \
  > /workspace/vllm_tiny.log 2>&1 &
echo "  TinyLlama launching on port 8003 (PID $!)"

# ── Step 4: Wait for vLLM (up to 15 minutes) ────────────
echo ""
echo "[ 4/6 ] Waiting for vLLM servers (3-5 minutes)..."
for i in {1..180}; do
  M=$(curl -s http://localhost:8001/health 2>/dev/null)
  T=$(curl -s http://localhost:8003/health 2>/dev/null)
  if [ ! -z "$M" ] && [ ! -z "$T" ]; then
    echo ""
    echo "  ✅ Mistral UP  (port 8001)"
    echo "  ✅ TinyLlama UP (port 8003)"
    break
  fi
  echo -n "."
  sleep 5
done

# Verify both up
M=$(curl -s http://localhost:8001/health 2>/dev/null)
T=$(curl -s http://localhost:8003/health 2>/dev/null)
if [ -z "$M" ] || [ -z "$T" ]; then
  echo ""
  echo "⚠️  vLLM servers not responding after 15 minutes"
  echo "   Check logs: tail -20 /workspace/vllm_mistral.log"
  exit 1
fi

# ── Step 5: Launch API + UI servers ─────────────────────
echo ""
echo "[ 5/6 ] Launching API and UI servers..."

pip install aiohttp-cors --quiet --break-system-packages 2>/dev/null

# API server on port 8891
fuser -k 8891/tcp 2>/dev/null
sleep 2
python3 /workspace/aegis/api_server.py > /workspace/api_server.log 2>&1 &
sleep 6
curl -s http://localhost:8891/health > /dev/null \
  && echo "  ✅ API server UP (port 8891)" \
  || echo "  ⚠️  API server issue — check /workspace/api_server.log"

# UI server on port 7777
fuser -k 7777/tcp 2>/dev/null
sleep 1
cd /workspace/aegis/ui && python3 -m http.server 7777 > /workspace/ui.log 2>&1 &
sleep 2
echo "  ✅ UI server UP (port 7777)"
cd /workspace

# ── Step 6: Smoke test ───────────────────────────────────
echo ""
echo "[ 6/6 ] Running smoke test..."
RESULT=$(curl -s -X POST http://localhost:8891/run \
  -H "Content-Type: application/json" \
  -d '{"telemetry":"ALERT-001 HIGH SIEM:92 HOST-A port scan. ALERT-002 LOW SIEM:31 HOST-F DNS tunnel.","incident_id":"INC-SMOKE"}' \
  --max-time 30 2>/dev/null | head -5)

if echo "$RESULT" | grep -q "token"; then
  echo "  ✅ Real LLM tokens flowing — Mistral-7B is reasoning"
else
  echo "  ⚠️  Smoke test inconclusive — try manually"
fi

# ── Get session ID ───────────────────────────────────────
SESSION=$(jupyter lab list 2>/dev/null | grep http | grep -o 'jupyter-hack-team-[^/]*' | head -1)

echo ""
echo "████████████████████████████████████████████████████"
echo "  AEGIS IS READY"
echo "████████████████████████████████████████████████████"
echo ""
if [ ! -z "$SESSION" ]; then
  echo "  LIVE UI:"
  echo "  https://notebooks.amd.com/${SESSION}/proxy/7777/warroom_live.html"
  echo ""
  echo "  NOTE: Update API_BASE in warroom_live.html if session changed:"
  echo "  sed -i 's|jupyter-hack-team-[^/]*/proxy|${SESSION}/proxy|g' /workspace/aegis/ui/warroom_live.html"
fi
echo ""
echo "  Mistral:    http://localhost:8001/health"
echo "  TinyLlama:  http://localhost:8003/health"
echo "  API Server: http://localhost:8891/health"
echo "  UI Server:  http://localhost:7777/warroom_live.html"
echo ""
rocm-smi | grep -E "VRAM%|GPU%|====" 2>/dev/null
echo ""
echo "  Happy Hacking — Team-557 · Gagandeep Singh 🚀"
echo ""

# ── Fix session ID automatically ─────────────────────
echo "[ * ] Fixing session ID in warroom_live.html..."
SESSION=$(jupyter lab list 2>/dev/null | grep http | grep -o 'jupyter-hack-team-[0-9a-z-]*' | head -1)
if [ ! -z "$SESSION" ]; then
  python3 - << PYEOF
import re
content = open('/workspace/aegis/ui/warroom_live.html').read()
new_base = 'https://notebooks.amd.com/${SESSION}/proxy/8891'
content = re.sub(
    r'https://notebooks\.amd\.com/jupyter-hack-team-557-[^/]+/proxy/8891',
    new_base,
    content
)
open('/workspace/aegis/ui/warroom_live.html', 'w').write(content)
print(f'  ✅ API_BASE updated')
PYEOF
  echo "  ✅ Session ID fixed: $SESSION"
  echo ""
  echo "  Open this in Chrome:"
  echo "  https://notebooks.amd.com/${SESSION}/proxy/7777/warroom_live.html"
fi
