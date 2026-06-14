# AEGIS — How to Use
**Enterprise Cyber Defense Framework**
**Technical Architect & Designer: Gagandeep Singh | Team-557 | AMD AI Hackathon 2026**

---

## Quick Start — One Command

```bash
cd /workspace && git clone https://github.com/Gsingh3001/aegis.git && bash aegis/start.sh
```

That's it. AEGIS will:
1. Download models if missing (Mistral-7B + TinyLlama)
2. Launch both vLLM servers on AMD MI300X
3. Wait for both models to be healthy
4. Launch API server on port 8891
5. Launch UI server on port 7777
6. Run a smoke test to confirm real LLM tokens flowing
7. Print your live URL

---

## Accessing the UI

After `start.sh` completes, open this in Chrome:
https://notebooks.amd.com/[YOUR-SESSION-ID]/proxy/7777/warroom_live.html

Replace `[YOUR-SESSION-ID]` with your actual Jupyter session ID.
Your session ID is the part of your JupyterLab URL between
`notebooks.amd.com/` and `/lab`.

**Example:**
https://notebooks.amd.com/jupyter-hack-team-557-260614144653-15d7cfa5/proxy/7777/warroom_live.html
---

## Running the War Room

### Step 1 — Check Backend Status
Look at the sidebar — Backend Status should show:
### Step 2 — Inject Telemetry
Three options:
- Click **Load: Diversion** — classic port scan masking DNS exfil
- Click **Load: Pharma** — pharmaceutical manufacturing sabotage
- Paste your own raw SIEM alerts into the text box

### Step 3 — Launch
Click **▶ Launch Real War Room**

Watch all 6 agents stream simultaneously:
- **Forensics** — analyses raw evidence only
- **Red Team** — maps adversary TTPs to MITRE ATT&CK
- **Inf. Defense** — proposes containment actions
- **Skeptic** — challenges the emerging consensus
- **CISO** — injects cost, legal, and regulatory context
- **Commander** — forces convergence and records dissent

### Step 4 — Decision Overlay
When the Commander completes, a decision overlay appears showing:
- The full decision with rationale
- What the Commander deliberately chose NOT to do
- Recorded dissent from the Skeptic
- Real SHA-256 hash of the decision artifact

### Step 5 — Stress Test Swarm
Click **Dismiss & Run Swarm** to run 100 adversarial attacker
variants against the decision. Watch the grid light up green
(survived) and red (bypassed).

---

## Updating Session ID

Every new AMD lab session gets a new session ID. Update it with:

```bash
SESSION="your-new-session-id-here"
sed -i "s|jupyter-hack-team-557-[^/]*/proxy|jupyter-hack-team-557-${SESSION}/proxy|g" \
  /workspace/aegis/ui/warroom_live.html
```

---

## Manual Server Management

If any server dies, restart individually:

### Restart Mistral 7B
```bash
python3 -m vllm.entrypoints.openai.api_server \
  --model /workspace/models/mistral7b \
  --port 8001 --gpu-memory-utilization 0.55 \
  --max-model-len 4096 --dtype float16 \
  > /workspace/vllm_mistral.log 2>&1 &
```

### Restart TinyLlama
```bash
python3 -m vllm.entrypoints.openai.api_server \
  --model /workspace/models/tinyllama \
  --port 8003 --gpu-memory-utilization 0.25 \
  --max-model-len 2048 --dtype float16 \
  > /workspace/vllm_tiny.log 2>&1 &
```

### Restart API Server
```bash
fuser -k 8891/tcp 2>/dev/null && sleep 2
python3 /workspace/aegis/api_server.py > /workspace/api_server.log 2>&1 &
```

### Restart UI Server
```bash
fuser -k 7777/tcp 2>/dev/null && sleep 1
cd /workspace/aegis/ui && python3 -m http.server 7777 > /dev/null 2>&1 &
```

### Check All Health
```bash
curl -s http://localhost:8001/health && echo "✅ Mistral"
curl -s http://localhost:8003/health && echo "✅ TinyLlama"
curl -s http://localhost:8891/health && echo "✅ API"
```

---

## Port Reference

| Port | Service | Purpose |
|------|---------|---------|
| 8001 | Mistral-7B vLLM | Main reasoning model |
| 8003 | TinyLlama vLLM | Fast swarm model |
| 8891 | AEGIS API Server | Bridges UI to GPU |
| 7777 | UI HTTP Server | Serves warroom_live.html |
| 8888 | JupyterLab | DO NOT USE for AEGIS |

---

## Test Scenarios

### Built-in (click buttons in UI)
1. **The Diversion** — port scan masking DNS exfiltration
2. **Pharma Sabotage** — recipe files modified, cold chain disabled

### Custom (paste into injection box)
Paste raw SIEM alerts in any format. The LLM agents will reason
about whatever you give them. No pre-analysis needed. Examples:

- **Operation Silent Crown** — £2.3B SWIFT payment interception
- **Operation Hollow Supply** — pharmaceutical sabotage
- **NHS Hospital Trust** — ransomware + drug dispensing compromise
- **Financial Bank** — credential stuffing + fraud threshold change
- **Operation APEX** — algorithmic trading + Kerberoasting

---

## FAQ

**Q: The UI shows "API not reachable" — what do I do?**
A: The API server died. Run:
```bash
fuser -k 8891/tcp 2>/dev/null && sleep 2
python3 /workspace/aegis/api_server.py > /workspace/api_server.log 2>&1 &
sleep 5
curl -s http://localhost:8891/health
```

**Q: Agents show "Error: Cannot connect to host localhost:8001"**
A: The vLLM servers died. Restart them using the commands above.
Models take 3-5 minutes to load on first start.

**Q: The response looks pre-written / generic**
A: This means the API errored and the UI showed a fallback.
Check `/workspace/api_server.log` for the error. Most likely
cause is vLLM servers not running.

**Q: start.sh dots keep running and never stop**
A: Models are still loading. ROCm kernel compilation takes
3-5 minutes. If dots run for more than 15 minutes, check:
```bash
tail -5 /workspace/vllm_mistral.log
tail -5 /workspace/vllm_tiny.log
```

**Q: I get a 404 on the warroom_live.html URL**
A: The UI server isn't running or is on the wrong port. Run:
```bash
cd /workspace/aegis/ui && python3 -m http.server 7777 > /dev/null 2>&1 &
```

**Q: I see a Jupyter login page asking for a token**
A: You're hitting port 8888 (Jupyter itself). Use port 7777 instead.
The correct URL uses `/proxy/7777/` not `/proxy/8888/`.

**Q: The session ID changed after logging back in**
A: Every AMD lab session gets a new ID. Update it:
```bash
SESSION="your-new-id"
sed -i "s|jupyter-hack-team-557-[^/]*/proxy|jupyter-hack-team-557-${SESSION}/proxy|g" \
  /workspace/aegis/ui/warroom_live.html
```

**Q: Models need downloading every session**
A: Models are stored in `/workspace/models/` which persists within
a session but resets between sessions. `start.sh` handles this
automatically — it checks and downloads if missing.

**Q: Can I use my own incident data?**
A: Yes. Paste any raw SIEM alerts, network telemetry, or log data
into the injection box. No formatting required. The agents will
reason about whatever you give them. The responses will be
completely different from the built-in scenarios.

**Q: Why does the Skeptic always disagree?**
A: By design. The Skeptic is mandated to challenge the emerging
consensus regardless of how strong it is. This prevents groupthink
and forces the Commander to earn convergence rather than assume it.

**Q: Why does the output differ every run?**
A: Because it's real LLM inference — not pre-written text.
Mistral-7B generates responses token by token each time.
Temperature and sampling mean no two runs are identical.
This is the proof of genuine intelligence.

**Q: Why does AEGIS need AMD MI300X specifically?**
A: Running 6 specialist models concurrently plus 100 adversarial
swarm variants requires 148GB+ GPU memory at peak load.
The NVIDIA H100 has 80GB — the panel does not fit.
The AMD MI300X with 192GB HBM3 is the enabling condition,
not a preference.

**Q: How do I add a new scenario?**
A: Edit `scenarios/library.py` and add a new entry. Or simply
paste the telemetry directly into the UI injection box without
adding it to the library.

**Q: Can I run AEGIS on a different GPU?**
A: The code is model-agnostic. The `ask()` interface in
`serving/vllm_backend.py` works with any OpenAI-compatible
endpoint. However, 6 concurrent models require significant VRAM.
The AMD MI300X is the only single GPU that fits the full panel.

**Q: How do I contribute or report issues?**
A: Raise an issue on GitHub:
https://github.com/Gsingh3001/aegis/issues
Note: Commercial use requires written approval from Gagandeep Singh.

---

## Project Structure

aegis/

├── start.sh                    ← One-command startup

├── api_server.py               ← Bridges UI to AMD GPU

├── config.py                   ← Configuration

├── README.md                   ← Project overview

├── HOW_TO_USE.md               ← This file

├── LICENSE                     ← All Rights Reserved

├── agents/

│   └── prompts.py              ← 7 agent system prompts

├── orchestrator/

│   └── engine.py               ← Debate engine + stress test

├── scenarios/

│   └── library.py              ← Built-in scenarios

├── serving/

│   └── vllm_backend.py         ← AMD vLLM backend

└── ui/

├── warroom_live.html        ← Real LLM UI (use this)

├── warroom_v4.html          ← Static demo UI

└── warroom.html             ← Base UI

---

## Support

For technical issues: check logs first
```bash
tail -20 /workspace/api_server.log
tail -20 /workspace/vllm_mistral.log
tail -20 /workspace/vllm_tiny.log
```

For licensing enquiries:
**Gagandeep Singh** — Gagan.singh7142@gmail.com

---

*© 2026 Gagandeep Singh. All Rights Reserved.*
*No commercial use without written approval.*
*AMD AI Hackathon 2026 — Team-557*
