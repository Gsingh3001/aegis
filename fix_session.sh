#!/bin/bash
# ══════════════════════════════════════════════════════
# AEGIS — Session Fix Script
# Run this after start.sh to fix the session ID
# ══════════════════════════════════════════════════════

# Get clean session ID without port
SESSION=$(jupyter lab list 2>/dev/null | grep http | grep -o 'jupyter-hack-team-[0-9a-z-]*' | head -1)

if [ -z "$SESSION" ]; then
  echo "❌ Could not detect session ID"
  echo "   Manually set it:"
  echo "   SESSION=jupyter-hack-team-557-XXXXXXXX-XXXXXXXX"
  exit 1
fi

echo "✅ Session detected: $SESSION"

# Fix API_BASE in warroom_live.html using Python (avoids sed doubling bug)
python3 - << PYEOF
import re
content = open('/workspace/aegis/ui/warroom_live.html').read()

# Replace any existing session ID with the correct one
new_base = f'https://notebooks.amd.com/${SESSION}/proxy/8891'
content = re.sub(
    r'https://notebooks\.amd\.com/jupyter-hack-team-557-[^/]+/proxy/8891',
    new_base,
    content
)

open('/workspace/aegis/ui/warroom_live.html', 'w').write(content)
print(f'✅ API_BASE updated to: {new_base}')
PYEOF

echo ""
echo "  Open this in Chrome:"
echo "  https://notebooks.amd.com/${SESSION}/proxy/7777/warroom_live.html"
