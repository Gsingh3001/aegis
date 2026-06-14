# AEGIS — Enterprise Cyber Defense Framework
**AMD AI Hackathon 2026 · Team-557 · Technical Architect: Gagandeep Singh**

## One Command Startup
```bash
bash start.sh
```

## What it does
1. Downloads models if not present (TinyLlama + Mistral 7B)
2. Launches vLLM on AMD MI300X (ports 8001 + 8003)
3. Waits for both servers to be healthy
4. Launches UI server on port 8889
5. Runs smoke test to confirm everything works

## Architecture
- **6 specialist AI agents** debating incidents to a decision
- **AMD MI300X 192GB HBM3** — holds the entire panel in memory
- **vLLM 0.7.1 + ROCm 7.0** — concurrent multi-model serving
- **120-variant stress test swarm** — proves the decision holds
- **NIST SP 800-61** full lifecycle coverage
- **Chain of custody** with SHA-256 immutable ledger

## Tech Stack
- Python 3.12 · vLLM 0.7.1 · ROCm 7.0
- Mistral-7B-Instruct-v0.3 (reasoning)
- TinyLlama-1.1B-Chat-v1.0 (swarm)
- asyncio · aiohttp · HuggingFace Hub

## Demo URL
http://localhost:8889/warroom_v4.html

## Scenarios
1. **The Diversion** — DNS exfil masked by loud port scan
2. **Infrastructure Hijack** — IaC drift + CI/CD compromise
3. **Ransomware + Vault** — backup corruption + air-gap targeting
4. **Operation Silent Crown** — £2.3B SWIFT payment interception

## Key Numbers
- Debate completes in **~7 seconds** on MI300X
- Stress test: **120 variants in ~2 seconds**
- Peak VRAM: **148GB** — impossible on NVIDIA H100 (80GB)
- Scenarios tested: **4 enterprise-grade APT scenarios**

## License & Copyright

Copyright (c) 2026 Gagandeep Singh. All Rights Reserved.

**No permission is granted to commercialise, distribute, or use this 
software for commercial purposes without prior written approval from 
Gagandeep Singh.**

Contact: Gagan.singh7142@gmail.com

Built during AMD AI Hackathon 2026 — Team-557
