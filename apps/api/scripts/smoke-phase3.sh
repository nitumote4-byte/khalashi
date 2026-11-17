#!/usr/bin/env bash
# Smoke test Phase 3 soft-launch harden: rate limits, spam guards, error codes
set -euo pipefail
BASE="${BASE_URL:-http://localhost:3000}"

jq_get() {
  python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"
}

echo "== health =="
curl -sf "$BASE/health" >/dev/null

PHONE="9111000001"

echo "== OTP rate limit (4th request → RATE_LIMITED) =="
for i in 1 2 3; do
  curl -sf -X POST "$BASE/auth/otp/request" -H 'Content-Type: application/json' \
    -d "{\"phone\":\"$PHONE\"}" >/dev/null
done
CODE=$(curl -s -o /tmp/otp_rl.json -w '%{http_code}' -X POST "$BASE/auth/otp/request" \
  -H 'Content-Type: application/json' -d "{\"phone\":\"$PHONE\"}")
test "$CODE" = "429"
python3 -c 'import json; d=json.load(open("/tmp/otp_rl.json")); assert d.get("code")=="RATE_LIMITED", d'
echo "OTP RATE_LIMITED OK"

echo "== login driver for spam guards =="
# Use a fresh phone not burned by OTP rate limit
DRV_PHONE="9111000099"
DRV_OTP=$(curl -sf -X POST "$BASE/auth/otp/request" -H 'Content-Type: application/json' \
  -d "{\"phone\":\"$DRV_PHONE\"}")
DRV_CODE=$(echo "$DRV_OTP" | jq_get "d['debugCode']")
DRV=$(curl -sf -X POST "$BASE/auth/otp/verify" -H 'Content-Type: application/json' \
  -d "{\"phone\":\"$DRV_PHONE\",\"code\":\"$DRV_CODE\"}")
DRV_TOKEN=$(echo "$DRV" | jq_get "d['token']")

DEPART=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
ist = timezone(timedelta(hours=5, minutes=30))
print((datetime.now(ist) + timedelta(days=3)).replace(hour=9, minute=0, second=0, microsecond=0).isoformat())
PY
)

echo "== duplicate open trip same route/day → SPAM_DUPLICATE_TRIP =="
curl -sf -X POST "$BASE/trips" -H "Authorization: Bearer $DRV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"origin\":\"Nagpur\",\"destination\":\"Indore\",\"departAt\":\"$DEPART\",\"seatsTotal\":2,\"fareInr\":500,\"carModel\":\"Baleno\",\"numberPlate\":\"MH31AA1111\",\"carColor\":\"Blue\"}" >/dev/null
DUP_CODE=$(curl -s -o /tmp/dup.json -w '%{http_code}' -X POST "$BASE/trips" \
  -H "Authorization: Bearer $DRV_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"origin\":\"Nagpur\",\"destination\":\"Indore\",\"departAt\":\"$DEPART\",\"seatsTotal\":2,\"fareInr\":500,\"carModel\":\"Baleno\",\"numberPlate\":\"MH31AA1111\",\"carColor\":\"Blue\"}")
test "$DUP_CODE" = "409"
python3 -c 'import json; d=json.load(open("/tmp/dup.json")); assert d.get("code")=="SPAM_DUPLICATE_TRIP", d'
echo "SPAM_DUPLICATE_TRIP OK"

echo "== depart too soon → DEPART_TOO_SOON =="
SOON=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(minutes=5)).isoformat())
PY
)
SOON_CODE=$(curl -s -o /tmp/soon.json -w '%{http_code}' -X POST "$BASE/trips" \
  -H "Authorization: Bearer $DRV_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"origin\":\"Goa\",\"destination\":\"Hubli\",\"departAt\":\"$SOON\",\"seatsTotal\":1,\"fareInr\":200,\"carModel\":\"Alto\",\"numberPlate\":\"GA01BB2222\",\"carColor\":\"Red\"}")
test "$SOON_CODE" = "400"
python3 -c 'import json; d=json.load(open("/tmp/soon.json")); assert d.get("code")=="DEPART_TOO_SOON", d'
echo "DEPART_TOO_SOON OK"

echo "== missing vehicle details → VALIDATION_ERROR =="
MISS_CODE=$(curl -s -o /tmp/miss_vehicle.json -w '%{http_code}' -X POST "$BASE/trips" \
  -H "Authorization: Bearer $DRV_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"origin\":\"Goa\",\"destination\":\"Hubli\",\"departAt\":\"$DEPART\",\"seatsTotal\":1,\"fareInr\":200}")
test "$MISS_CODE" = "400"
echo "vehicle required OK"

echo "== unauthorized has code =="
UNAUTH=$(curl -s -o /tmp/unauth.json -w '%{http_code}' "$BASE/trips/mine")
test "$UNAUTH" = "401"
python3 -c 'import json; d=json.load(open("/tmp/unauth.json")); assert d.get("code")=="UNAUTHORIZED", d'
echo "UNAUTHORIZED code OK"

echo "SMOKE PHASE3 OK"
