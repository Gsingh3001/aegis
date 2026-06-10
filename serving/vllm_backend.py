import aiohttp, json, sys
sys.path.insert(0, '/workspace/aegis')
from orchestrator.engine import register_backend

class VLLMBackend:
    def __init__(self, base_url, model):
        self.base_url = base_url.rstrip("/")
        self.model = model
        self._session = None
    async def generate(self, system, user, max_tokens=300):
        if not self._session or self._session.closed:
            import aiohttp
            self._session = aiohttp.ClientSession()
        payload = {
            "model": self.model,
            "messages": [{"role":"system","content":system},{"role":"user","content":user}],
            "max_tokens": max_tokens, "temperature": 0.7, "stream": True
        }
        async with self._session.post(f"{self.base_url}/chat/completions", json=payload) as resp:
            if resp.status != 200:
                raise RuntimeError(f"vLLM {resp.status}: {await resp.text()}")
            async for line in resp.content:
                line = line.decode("utf-8").strip()
                if not line or line == "data: [DONE]": continue
                if line.startswith("data: "):
                    try:
                        c = json.loads(line[6:])["choices"][0].get("delta",{}).get("content","")
                        if c: yield c
                    except: continue

def install_vllm_backends(
    main_url="http://localhost:8001/v1",
    main_model="/workspace/models/mistral7b",
    fast_url="http://localhost:8003/v1",
    fast_model="/workspace/models/tinyllama"):
    register_backend("main", VLLMBackend(main_url, main_model))
    register_backend("fast", VLLMBackend(fast_url, fast_model))
    print("✅ Backends ready — main: mistral7b | fast: tinyllama")
