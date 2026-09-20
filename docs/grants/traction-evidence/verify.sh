#!/usr/bin/env bash
# verify.sh — re-hash every record and compare against manifest.json.
# Exits non-zero if any record is missing or has been altered.
set -euo pipefail
cd "$(dirname "$0")"

command -v jq >/dev/null 2>&1 || { echo "need jq: brew install jq"; exit 2; }

fail=0
count=0
# Read key+sha256 pairs from manifest.json with jq.
while IFS=$'\t' read -r key sha; do
  [ -z "$key" ] && continue
  rel="${key#collect/}"
  file="records/$rel"
  if [ ! -f "$file" ]; then
    echo "MISSING: $file"; fail=1; continue
  fi
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  count=$((count+1))
  if [ "$actual" != "$sha" ]; then
    echo "HASH MISMATCH: $file"; echo "  manifest: $sha"; echo "  actual:   $actual"; fail=1
  fi
done < <(jq -r '.[] | [.key, .sha256] | @tsv' manifest.json)

echo "checked $count records"
if [ "$fail" -eq 0 ]; then echo "OK — all hashes match"; else echo "FAILED"; exit 1; fi

# Re-derive the headline numbers from the raw records:
echo "--- summary re-derived from raw records ---"
cat records/pass/*/*.json records/fail/*/*.json 2>/dev/null | jq -s '
  def is_test: .address == "0xa1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1";
  { totalScored: length,
    pass: ([.[] | select(.kind=="pass")] | length),
    fail: ([.[] | select(.kind=="fail")] | length),
    uniqueAddresses_excl_test: ([.[] | select(is_test|not) | .address | ascii_downcase] | unique | length),
    uniqueMissions: ([.[].missionId] | unique | length),
    avgPassScore: ([.[] | select(.kind=="pass") | .score] | add / length) }'
echo "on-chain tx-receipts: $(find records/tx-receipt -name '*.json' | wc -l | tr -d ' ')"

