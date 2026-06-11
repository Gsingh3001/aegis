#!/bin/bash
# ══════════════════════════════════════════════════════
# AEGIS — One Command Startup Script
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
echo "[ 1/5 ] Checking models..."

if [ ! -d "/workspace/models/tinyllama" ]; then
  echo "  Downloading TinyLlama..."
  python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('TinyLlama/TinyLlama-1.1B-Chat-v1.0', local_dir='/workspace/models/tinyllama')
print('TinyLlama DONE')
" > /workspace/dl_tiny.log 2>&1 &
else
  echo "  ✅ TinyLlama already present"
fi

if [ ! -d "/workspace/models/mistral7b" ]; then
  echo "  Downloading Mistral 7B..."
  python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('mistralai/Mistral-7B-Instruct-v0.3', local_dir='/workspace/models/mistral7b')
print('Mistral DONE')
" > /workspace/dl_mistral.log 2>&1 &
else
  echo "  ✅ Mistral 7B already present"
fi

# Wait for downloads if they were needed
if [ -f /workspace/dl_tiny.log ] || [ -f /workspace/dl_mistral.log ]; then
  echo "  Waiting for model downloads..."
  wait
  echo "  ✅ Models ready"
fi

# ── Step 2: Launch vLLM servers ─────────────────────────
echo ""
echo "[ 2/5 ] Launching vLLM servers..."

# Kill any existing instances
pkill -f "vllm.entrypoints" 2>/dev/null
sleep 3

# Launch Mistral on port 8001
python3 -m vllm.entrypoints.openai.api_server \
  --model /workspace/models/mistral7b \
  --port 8001 \
  --gpu-memory-utilization 0.55 \
  --max-model-len 4096 \
  --dtype float16 \
  > /workspace/vllm_mistral.log 2>&1 &
echo "  Mistral 7B launching on port 8001 (PID $!)"

# Launch TinyLlama on port 8003
python3 -m vllm.entrypoints.openai.api_server \
  --model /workspace/models/tinyllama \
  --port 8003 \
  --gpu-memory-utilization 0.25 \
  --max-model-len 2048 \
  --dtype float16 \
  > /workspace/vllm_tiny.log 2>&1 &
echo "  TinyLlama launching on port 8003 (PID $!)"

# ── Step 3: Wait for both servers ───────────────────────
echo ""
echo "[ 3/5 ] Waiting for servers to be ready..."
echo "  (This takes 3-5 minutes on first load)"

for i in {1..60}; do
  M=$(curl -s http://localhost:8001/health 2>/dev/null)
  T=$(curl -s http://localhost:8003/health 2>/dev/null)
  if [ ! -z "$M" ] && [ ! -z "$T" ]; then
    echo ""
    echo "  ✅ Mistral UP  (port 8001)"
    echo "  ✅ TinyLlama UP (port 8003)"
    break
  fi
  echo -n "  Attempt $i/60 — waiting 10s..."
  if [ ! -z "$M" ]; then echo -n " Mistral✅"; else echo -n " Mistral⏳"; fi
  if [ ! -z "$T" ]; then echo " TinyLlama✅"; else echo " TinyLlama⏳"; fi
  sleep 10
done

# ── Step 4: Launch UI server ─────────────────────────────
echo ""
echo "[ 4/5 ] Launching UI server on port 8889..."
pkill -f "http.server 8889" 2>/dev/null
sleep 1
cd /workspace/aegis/ui && python3 -m http.server 8889 > /workspace/ui.log 2>&1 &
echo "  ✅ UI server running (PID $!)"

# ── Step 5: Run smoke test ───────────────────────────────
echo ""
echo "[ 5/5 ] Running smoke test..."
cd /workspace && python3 << 'PYEOF'
import asyncio, sys
sys.path.insert(0, '/workspace/aegis')
from serving.vllm_backend import install_vllm_backends
from orchestrator.engine import run_debate
from scenarios.library import get_scenario

install_vllm_backends(
    main_url="http://localhost:8001/v1",
    main_model="/workspace/models/mistral7b",
    fast_url="http://localhost:8003/v1",
    fast_model="/workspace/models/tinyllama"
)

scenario = get_scenario("diversion")

async def test():
    ctx, decision = await run_debate(
        scenario["id"], scenario["telemetry"])
    print(f"  ✅ Debate complete in {decision.elapsed_s:.1f}s")
    print(f"  ✅ Decision: {decision.decision[:80]}...")
    print(f"  ✅ Confidence: {decision.confidence}%")

asyncio.run(test())
PYEOF

# ── Done ─────────────────────────────────────────────────
echo ""
echo "████████████████████████████████████████████████████"
echo "  AEGIS IS READY"
echo "████████████████████████████████████████████████████"
echo ""
echo "  UI:      http://localhost:8889/warroom_v4.html"
echo "  Mistral: http://localhost:8001/health"
echo "  Tiny:    http://localhost:8003/health"
echo ""
echo "  rocm-smi output:"
rocm-smi | grep -E "VRAM|GPU%|Device|===="
echo ""
echo "  To run the full war room:"
echo "  cd /workspace && python3 -c \""
echo "  import asyncio,sys; sys.path.insert(0,'/workspace/aegis')"
echo "  from serving.vllm_backend import install_vllm_backends"
echo "  from orchestrator.engine import run_debate"
echo "  from scenarios.library import get_scenario"
echo "  \""
echo ""
echo "  Happy Hacking — Team-557 · Gagandeep Singh 🚀"
echo ""
