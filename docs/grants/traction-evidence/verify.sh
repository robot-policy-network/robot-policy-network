#!/usr/bin/env bash
# verify.sh — independently re-derive every headline figure from the raw
# records. Needs: gunzip (built-in), jq (brew install jq).
set -euo pipefail
cd "$(dirname "$0")"

echo "=== 1. integrity: re-hash every uncompressed day file ==="
fail=0
while IFS=$'\t' read -r file records rawsha; do
  [ -z "$file" ] && continue
  actual=$(gunzip -c "records/$file" | shasum -a 256 | awk '{print $1}')
  if [ "$actual" != "$rawsha" ]; then echo "MISMATCH: $file"; fail=1; fi
done < <(jq -r '.files[] | [.file, (.records|tostring), .rawSha256] | @tsv' manifest.json)
[ "$fail" -eq 0 ] && echo "all day-file hashes match" || { echo "HASH FAILURE"; exit 1; }

echo
echo "=== 2. re-derive the headline stats ==="
gunzip -c records/*.jsonl.gz | jq -s '
  def addr: (.address // "" ) | ascii_downcase;
  { totalRecords: length,
    uniqueAddresses: ([ .[] | addr | select(startswith("0x")) ] | unique | length),
    pass:  ([ .[] | select(.kind=="pass") ] | length),
    fail:  ([ .[] | select(.kind=="fail") ] | length),
    passRatePct: (([ .[] | select(.kind=="pass") ] | length) * 100.0 / length * 100 | round / 100),
    uniqueMissions: ([ .[] | .missionId | select(.!=null) ] | unique | length),
    avgPassScore: ([ .[] | select(.kind=="pass") | .score | numbers ] | add / length * 10 | round / 10),
    avgFailScore: (([ .[] | select(.kind=="fail") | .score | numbers ] | if length>0 then add/length*10|round/10 else null end)),
    modes: (group_by(.mode) | map({(.[0].mode): length}) | add)
  }'

echo
echo "=== 3. per-day volume ==="
for f in records/*.jsonl.gz; do
  printf '%s  %s records\n' "$(basename "$f" .jsonl.gz)" "$(gunzip -c "$f" | grep -c .)"
done
