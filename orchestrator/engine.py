import asyncio, json, time, sys
from dataclasses import dataclass, field
from typing import Dict, List
sys.path.insert(0, '/workspace/aegis')
from agents.prompts import SYSTEM_PROMPTS, DEBATE_ROUNDS

@dataclass
class AgentMessage:
    role: str
    content: str

@dataclass
class DebateContext:
    incident_id: str
    telemetry: dict
    messages: List[AgentMessage] = field(default_factory=list)
    def as_thread(self):
        out = [f"INCIDENT: {self.incident_id}", f"TELEMETRY:\n{json.dumps(self.telemetry, indent=2)}"]
        for m in self.messages:
            out.append(f"\n[{m.role}]\n{m.content}")
        return "\n".join(out)

@dataclass
class DecisionArtifact:
    incident_id: str
    decision: str
    dissent: str
    confidence: int
    raw: str
    elapsed_s: float

BACKENDS: Dict[str, object] = {}
ROLE_TO_BACKEND = {r: "main" for r in ["FORENSICS","RED","BLUE","SKEPTIC","CISO","COMMANDER"]}
ROLE_TO_BACKEND["ATTACKER"] = "fast"

def register_backend(name, backend):
    BACKENDS[name] = backend

async def ask(role, context, extra="", stream_callback=None, max_tokens=300):
    backend = BACKENDS.get(ROLE_TO_BACKEND.get(role,"main")) or BACKENDS.get("main")
    if not backend:
        raise RuntimeError("No backend registered. Call install_vllm_backends() first.")
    user = context.as_thread() + (f"\n\n{extra}" if extra else "")
    tokens = []
    async for token in backend.generate(SYSTEM_PROMPTS[role], user, max_tokens=max_tokens):
        tokens.append(token)
        if stream_callback:
            stream_callback(role, token)
    return AgentMessage(role=role, content="".join(tokens))

async def run_debate(incident_id, telemetry, stream_callback=None, on_round_complete=None):
    ctx = DebateContext(incident_id=incident_id, telemetry=telemetry)
    start = time.time()
    for round_num, roles in DEBATE_ROUNDS.items():
        extras = {}
        if round_num == 2:
            extras["SKEPTIC"] = "CRITICAL: Look for a DIVERSION. Is the loudest alert covering quieter exfil?"
        tasks = [ask(r, ctx, extras.get(r,""), stream_callback) for r in roles]
        msgs = await asyncio.gather(*tasks)
        for m in msgs: ctx.messages.append(m)
        if on_round_complete: on_round_complete(round_num, list(msgs))
    cmd = next((m for m in reversed(ctx.messages) if m.role=="COMMANDER"), None)
    artifact = None
    if cmd:
        def ex(label):
            for line in cmd.content.splitlines():
                if line.strip().startswith(label+":"):
                    return line.split(":",1)[1].strip()
            return ""
        try: conf = int(ex("CONFIDENCE").replace("%","").strip())
        except: conf = 75
        artifact = DecisionArtifact(
            incident_id=incident_id, decision=ex("DECISION"),
            dissent=ex("RECORDED DISSENT"), confidence=conf,
            raw=cmd.content, elapsed_s=time.time()-start)
    return ctx, artifact

async def run_stress_test(artifact, context, n=100, on_progress=None):
    start = time.time()
    sem = asyncio.Semaphore(30)
    vectors = [
        "DNS-over-HTTPS port 443 CDN bypass",
        "Scheduled task persistence survives isolation",
        "Shadow service account not yet revoked",
        "Pivot via unmanaged IoT device on subnet",
        "Data staged in cloud storage before containment",
        "DGA-based C2 independent of blocked domain",
        "Pass-the-Hash using cached NTLM credentials",
        "WMI lateral movement via existing session",
    ]
    decision_lower = (artifact.decision + " " + artifact.raw).lower()
    covered = [k for k in ["dns","block","isolat","revok","firewall","monitor"] if k in decision_lower]
    async def variant(seed):
        async with sem:
            vec = vectors[seed % len(vectors)]
            backend = BACKENDS.get("fast") or BACKENDS.get("main")
            tokens = []
            async for t in backend.generate(SYSTEM_PROMPTS["ATTACKER"],
                f"Decision: {artifact.decision}\nFind bypass using: {vec}", max_tokens=80):
                tokens.append(t)
            breached = not any(k in "".join(tokens).lower() for k in covered)
            return {"vector": vec, "breached": breached}
    results, done = [], 0
    for coro in asyncio.as_completed([variant(i) for i in range(n)]):
        r = await coro
        results.append(r)
        done += 1
        if on_progress: on_progress(done, n)
    breached = [r for r in results if r["breached"]]
    survived = n - len(breached)
    from collections import Counter
    top = Counter(r["vector"] for r in breached).most_common(4)
    return {
        "n": n, "survived": survived,
        "headline": f"Survived {survived}/{n} ({round(survived/n*100)}%)",
        "top_failure_modes": [{"vector":v,"count":c} for v,c in top],
        "elapsed_s": time.time()-start
    }
