#!/usr/bin/env bash
# Smoke test Phase 2 trip/book/cancel against a running API on :3000
set -euo pipefail
BASE="${BASE_URL:-http://localhost:3000}"

jq_get() {
  python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"
}

echo "== health =="
curl -sf "$BASE/health" >/dev/null

echo "== OTP driver =="
DRV_OTP=$(curl -sf -X POST "$BASE/auth/otp/request" -H 'Content-Type: application/json' \
  -d '{"phone":"9000000001"}')
DRV_CODE=$(echo "$DRV_OTP" | jq_get "d['debugCode']")
DRV=$(curl -sf -X POST "$BASE/auth/otp/verify" -H 'Content-Type: application/json' \
  -d "{\"phone\":\"9000000001\",\"code\":\"$DRV_CODE\"}")
DRV_TOKEN=$(echo "$DRV" | jq_get "d['token']")

echo "== OTP traveller =="
TRV_OTP=$(curl -sf -X POST "$BASE/auth/otp/request" -H 'Content-Type: application/json' \
  -d '{"phone":"9000000002"}')
TRV_CODE=$(echo "$TRV_OTP" | jq_get "d['debugCode']")
TRV=$(curl -sf -X POST "$BASE/auth/otp/verify" -H 'Content-Type: application/json' \
  -d "{\"phone\":\"9000000002\",\"code\":\"$TRV_CODE\"}")
TRV_TOKEN=$(echo "$TRV" | jq_get "d['token']")

DEPART=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
ist = timezone(timedelta(hours=5, minutes=30))
print((datetime.now(ist) + timedelta(days=2)).replace(hour=6, minute=30, second=0, microsecond=0).isoformat())
PY
)
DATE=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
ist = timezone(timedelta(hours=5, minutes=30))
print((datetime.now(ist) + timedelta(days=2)).strftime("%Y-%m-%d"))
PY
)

# Unique dest so soft-launch duplicate-route guard doesn't fail on re-runs
SUFFIX=$(date +%s)
DEST="Mumbai $SUFFIX"

echo "== create trip =="
TRIP=$(curl -sf -X POST "$BASE/trips" -H "Authorization: Bearer $DRV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"origin\":\"Pune\",\"destination\":\"$DEST\",\"departAt\":\"$DEPART\",\"seatsTotal\":2,\"fareInr\":450}")
TRIP_ID=$(echo "$TRIP" | jq_get "d['trip']['id']")
echo "trip=$TRIP_ID"

echo "== search =="
DEST_Q=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$DEST")
SEARCH=$(curl -sf "$BASE/trips/search?origin=Pune&destination=$DEST_Q&date=$DATE" \
  -H "Authorization: Bearer $TRV_TOKEN")
COUNT=$(echo "$SEARCH" | jq_get "len(d['trips'])")
test "$COUNT" -ge 1

echo "== search Bombay alias =="
# Separate date offset so it never collides with the unique DEST trip above
ALIAS_DEPART=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
ist = timezone(timedelta(hours=5, minutes=30))
print((datetime.now(ist) + timedelta(days=5)).replace(hour=7, minute=0, second=0, microsecond=0).isoformat())
PY
)
ALIAS_DATE=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
ist = timezone(timedelta(hours=5, minutes=30))
print((datetime.now(ist) + timedelta(days=5)).strftime("%Y-%m-%d"))
PY
)
curl -s -X POST "$BASE/trips" -H "Authorization: Bearer $DRV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"origin\":\"Pune\",\"destination\":\"Mumbai\",\"departAt\":\"$ALIAS_DEPART\",\"seatsTotal\":1,\"fareInr\":400}" >/dev/null || true
ALIAS=$(curl -sf "$BASE/trips/search?origin=Pune&destination=Bombay&date=$ALIAS_DATE" \
  -H "Authorization: Bearer $TRV_TOKEN")
ALIAS_COUNT=$(echo "$ALIAS" | jq_get "len(d['trips'])")
test "$ALIAS_COUNT" -ge 1

echo "== book 1 seat window =="
BOOK=$(curl -sf -X POST "$BASE/trips/$TRIP_ID/bookings" -H "Authorization: Bearer $TRV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"seats":1,"seatPreference":"window"}')
BOOK_ID=$(echo "$BOOK" | jq_get "d['booking']['id']")
LEFT=$(echo "$BOOK" | jq_get "d['booking']['trip']['seatsLeft']")
test "$LEFT" = "1"

echo "== concurrent last-seat race =="
auth_token() {
  local phone=$1
  local otp
  otp=$(curl -sf -X POST "$BASE/auth/otp/request" -H 'Content-Type: application/json' -d "{\"phone\":\"$phone\"}")
  local code
  code=$(echo "$otp" | jq_get "d['debugCode']")
  curl -sf -X POST "$BASE/auth/otp/verify" -H 'Content-Type: application/json' \
    -d "{\"phone\":\"$phone\",\"code\":\"$code\"}" | jq_get "d['token']"
}
TRV2_TOKEN=$(auth_token 9000000003)
TRV3_TOKEN=$(auth_token 9000000004)

curl -s -o /tmp/book_a.json -w '%{http_code}' -X POST "$BASE/trips/$TRIP_ID/bookings" \
  -H "Authorization: Bearer $TRV2_TOKEN" -H 'Content-Type: application/json' \
  -d '{"seats":1,"seatPreference":"front"}' >/tmp/code_a.txt &
PID_A=$!
curl -s -o /tmp/book_b.json -w '%{http_code}' -X POST "$BASE/trips/$TRIP_ID/bookings" \
  -H "Authorization: Bearer $TRV3_TOKEN" -H 'Content-Type: application/json' \
  -d '{"seats":1,"seatPreference":"any"}' >/tmp/code_b.txt &
PID_B=$!
wait $PID_A $PID_B
A=$(python3 -c 'import json; d=json.load(open("/tmp/book_a.json")); print("OK" if d.get("ok") else d.get("code") or "ERR")')
B=$(python3 -c 'import json; d=json.load(open("/tmp/book_b.json")); print("OK" if d.get("ok") else d.get("code") or "ERR")')
echo "race results: $A / $B"
echo "$A $B" | grep -q 'SEATS_FULL'
echo "$A $B" | grep -q 'OK'

echo "== cancel booking restores seat =="
curl -sf -X POST "$BASE/bookings/$BOOK_ID/cancel" -H "Authorization: Bearer $TRV_TOKEN" \
  -H 'Content-Type: application/json' -d '{}' >/dev/null
DETAIL=$(curl -sf "$BASE/trips/$TRIP_ID" -H "Authorization: Bearer $DRV_TOKEN")
LEFT2=$(echo "$DETAIL" | jq_get "d['trip']['seatsLeft']")
echo "seats_left after cancel=$LEFT2"
test "$LEFT2" = "1"

echo "== cancel trip cascades =="
TRIP2=$(curl -sf -X POST "$BASE/trips" -H "Authorization: Bearer $DRV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"origin\":\"Delhi\",\"destination\":\"Jaipur\",\"departAt\":\"$DEPART\",\"seatsTotal\":3,\"fareInr\":300}")
TRIP2_ID=$(echo "$TRIP2" | jq_get "d['trip']['id']")
curl -sf -X POST "$BASE/trips/$TRIP2_ID/bookings" -H "Authorization: Bearer $TRV_TOKEN" \
  -H 'Content-Type: application/json' -d '{"seats":2,"seatPreference":"any"}' >/dev/null
CANCEL=$(curl -sf -X POST "$BASE/trips/$TRIP2_ID/cancel" -H "Authorization: Bearer $DRV_TOKEN" \
  -H 'Content-Type: application/json' -d '{}')
STATUS=$(echo "$CANCEL" | jq_get "d['trip']['status']")
test "$STATUS" = "cancelled"
MINE=$(curl -sf "$BASE/bookings/mine" -H "Authorization: Bearer $TRV_TOKEN")
echo "$MINE" | jq_get "any(b['status']=='cancelled' for b in d['bookings'])" | grep -qi true

echo "SMOKE OK"
