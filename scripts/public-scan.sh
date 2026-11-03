#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "=== public-scan: $ROOT ==="
fail=0
# Content scan: skip this script and denylist checkers (they intentionally name banned tokens).
search() {
  local pat="$1"
  grep -RInE --exclude-dir=.git --exclude-dir=node_modules \
    --exclude='public-scan.sh' --exclude='init-guided.sh' \
    --exclude='*.png' --exclude='*.jpg' "$pat" . 2>/dev/null || true
}
echo "-- high-confidence secret markers --"
hits=$(search '(BEGIN (RSA |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|Bearer [A-Za-z0-9._\\-]{20,}|xox[baprs]-)')
hits=$(printf '%s\n' "$hits" | grep -v 'docs/05-security' | grep -v '<[A-Z_]+>' || true)
if [ -n "${hits}" ]; then echo "$hits"; fail=1; else echo "OK: no high-confidence secret markers"; fi
echo "-- private / link-local IPs (exclude 127.0.0.1) --"
hits=$(search '\b(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3})\b' | grep -v '127\.0\.0\.1' || true)
if [ -n "${hits}" ]; then echo "$hits"; fail=1; else echo "OK: no private IP literals"; fi
echo "-- email addresses --"
hits=$(search '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | grep -vE 'example\.com|noreply@' || true)
if [ -n "${hits}" ]; then echo "$hits"; fail=1; else echo "OK: no emails"; fi
echo "-- banned product / org / person fingerprints --"
hits=$(search '智衣|肖晓霖|肖晓林|zhiyimes|iipcloud|sanzhi/private|macdeMac|a49da6a7-b73e-48c7-8108-bff25e6bcbd4|mac-bridge\.zhiyimes|codeup\.aliyun\.com/sanzhi')
if [ -n "${hits}" ]; then echo "$hits"; fail=1; else echo "OK: no banned fingerprints"; fi
echo "-- print line must stay excluded --"
if [ -d roles/zhiyi-print ] || [ -d roles/print ] || [ -d zhiyi-print ]; then
  echo "FAIL: print role dir present"; fail=1
else
  echo "OK: no print role dir"
fi
if [ "$fail" -ne 0 ]; then echo "=== public-scan FAILED ==="; exit 1; fi
echo "=== public-scan PASSED ==="
