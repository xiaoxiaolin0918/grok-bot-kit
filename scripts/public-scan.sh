#!/usr/bin/env bash
# Pre-publish scan for a Public GitHub tree. Exit 1 on findings.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "=== public-scan: $ROOT ==="
fail=0

echo "-- high-confidence secret markers --"
if rg -n --glob '!.git/*' --glob '!scripts/public-scan.sh' \
  -e 'ghp_[A-Za-z0-9]{20,}' \
  -e 'github_pat_[A-Za-z0-9_]{20,}' \
  -e 'sk-[A-Za-z0-9]{20,}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
  -e '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----' \
  -e 'AKIA[0-9A-Z]{16}' \
  . ; then
  echo "FAIL: secret-like pattern"
  fail=1
else
  echo "OK: no high-confidence secret markers"
fi

echo "-- private / link-local IPs (exclude 127.0.0.1 docs) --"
if rg -n --glob '!.git/*' --glob '!scripts/public-scan.sh' \
  -e '\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b' \
  -e '\b172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}\b' \
  -e '\b192\.168\.[0-9]{1,3}\.[0-9]{1,3}\b' \
  -e '\b100\.(6[4-9]|[7-9][0-9]|1[0-2][0-9])\.[0-9]{1,3}\.[0-9]{1,3}\b' \
  . ; then
  echo "FAIL: private IP-like address"
  fail=1
else
  echo "OK: no private IP literals"
fi

echo "-- email addresses --"
if rg -n --glob '!.git/*' --glob '!LICENSE' --glob '!scripts/public-scan.sh' \
  -e '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' \
  . ; then
  echo "FAIL: email-like string (use placeholders)"
  fail=1
else
  echo "OK: no emails"
fi

echo "-- banned product / org / person fingerprints --"
# Note: do NOT put placeholder tokens like <ORG> in this list — they appear intentionally.
if rg -n --glob '!.git/*' --glob '!scripts/public-scan.sh' \
  -e '肖晓霖|肖晓林' \
  -e 'zhiyimes' \
  -e 'sanzhi/private' \
  -e 'iipcloud|iipmes' \
  -e 'zhiyi-bot-kit|zhiyi-cli' \
  -e 'com\.zhiyi\.' \
  -e '智衣' \
  -e 'a49da6a7-b73e-48c7-8108-bff25e6bcbd4' \
  -e '/Users/mac/Projects/grok-bot-revival' \
  -e 'mac-bridge\.zhiyimes' \
  -e 'codeup\.aliyun\.com/sanzhi' \
  . ; then
  echo "FAIL: internal fingerprint"
  fail=1
else
  echo "OK: no banned fingerprints"
fi

echo "-- print line must stay excluded --"
if [[ -d roles/zhiyi-print || -d zhiyi-print || -d roles/print ]]; then
  echo "FAIL: print role directory present"
  fail=1
else
  echo "OK: no print role dir"
fi

if [[ $fail -ne 0 ]]; then
  echo "=== public-scan FAILED ==="
  exit 1
fi
echo "=== public-scan PASSED ==="
