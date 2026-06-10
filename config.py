# Ensure your orchestrator configuration maps exactly to the live model IDs
ROLE_TO_BACKEND = {
    "Skeptic": "http://localhost:8001/v1",       # Mistral 7B (Reasoning)
    "CISO": "http://localhost:8001/v1",          # Mistral 7B
    "Incident Commander": "http://localhost:8001/v1", # Mistral 7B
    
    "Forensics": "http://localhost:8001/v1",     # Mistral 7B (Security context)
    "Red": "http://localhost:8001/v1",           # Mistral 7B
    
    "Blue": "http://localhost:8003/v1",          # TinyLlama (Fast execution)
    "ATTACKER": "http://localhost:8003/v1"       # TinyLlama (High-N Swarm)
}

MODEL_MAPPING = {
    "http://localhost:8001/v1": "/workspace/models/mistral7b",
    "http://localhost:8003/v1": "/workspace/models/tinyllama"
}
