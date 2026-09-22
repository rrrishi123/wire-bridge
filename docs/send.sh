#!/usr/bin/env bash
# usage: send.sh <METHOD> <URL> [why]   — writes an envelope + pushes. Run from a bridge clone.
set -e
M="${1:?method}"; U="${2:?url}"; WHY="${3:-federation call}"
ULID=$(python3 -c "import random; a='0123456789ABCDEFGHJKMNPQRSTVWXYZ'; print(''.join(random.choice(a) for _ in range(26)))")
python3 - "$ULID" "$M" "$U" "$WHY" > "commands/$ULID.json" <<'PY'
import json,sys,time
u,m,url,why=sys.argv[1:5]
print(json.dumps({"schema":"gitbroker/envelope/v1","ulid":u,"seq":1,"atom":"call","agent":"far","why":why,
 "proposed_at":time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),
 "call":{"method":m,"url":url}}, indent=2))
PY
git add "commands/$ULID.json"; git commit -q -m "propose $M $U ($ULID)"; git pull -q --no-edit origin main || true; git push -q origin main
echo "sent $ULID — poll receipts/$ULID.json"
