#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANTENNA_PIPELINE_ROOT="$ROOT"
KERNEL_PATH="${WolframKernel:-/Applications/Wolfram.app/Contents/MacOS/WolframKernel}"

if ! command -v wolframscript >/dev/null 2>&1; then
  echo "wolframscript was not found on PATH."
  exit 1
fi

pass_count=0
fail_count=0

run_case() {
  local name="$1"
  local body="$2"
  local tmp

  tmp="$(mktemp /tmp/antenna_release_case.XXXXXX.wl)"

  cat > "$tmp" <<'EOF'
repoRoot = Environment["ANTENNA_PIPELINE_ROOT"];
Get[FileNameJoin[{repoRoot, "AntennaPipeline.wl"}]];
EOF
  printf '%s\n' "$body" >> "$tmp"

  echo "Running: $name"
  if WolframKernel="$KERNEL_PATH" wolframscript -file "$tmp"; then
    echo "$name | passed=True"
    pass_count=$((pass_count + 1))
  else
    echo "$name | passed=False"
    fail_count=$((fail_count + 1))
  fi

  rm -f "$tmp"
}

run_case "BuildAntenna A20" \
'result = BuildAntenna[A, 2, 0];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAntenna A30" \
'result = BuildAntenna[A, 3, 0];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAndIntegrate A30" \
'result = BuildAndIntegrateAntenna[A, 3, 0];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAndIntegrate A30 record" \
'result = BuildAndIntegrateAntenna[A, 3, 0, ReturnRecord -> True];
If[
  AntennaRunRecordQ[result] &&
  KeyExistsQ[AntennaRunRecordData[result], "Result"] &&
  KeyExistsQ[AntennaRunRecordData[result], "IntermediateSteps"] &&
  KeyExistsQ[AntennaRunRecordData[result], "Diagnostics"],
  Exit[0],
  Exit[1]
];'

run_case "BuildAndIntegrate A21" \
'result = BuildAndIntegrateAntenna[A, 2, 1];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAndIntegrate A31" \
'result = BuildAndIntegrateAntenna[A, 3, 1];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAndIntegrate A22" \
'result = BuildAndIntegrateAntenna[A, 2, 2];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAndIntegrate A40 leading" \
'result = BuildAndIntegrateAntenna[A, 4, 0, Component -> Leading];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAndIntegrate B40" \
'result = BuildAndIntegrateAntenna[B, 4, 0];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildAndIntegrate C40" \
'result = BuildAndIntegrateAntenna[C, 4, 0];
If[result === $Failed, Exit[1], Exit[0]];'

run_case "BuildRRatio SMQCD massless" \
'result = BuildRRatio[SMQCD, quarkMass -> 0];
If[result === $Failed, Exit[1], Exit[0]];'

echo
echo "=== RELEASE SCOPE ==="
echo "This script checks only the supported massless release matrix."
echo "Experimental massive A30 and D30 routes are intentionally excluded."

echo
echo "=== FINAL COUNTS ==="
echo "NumPassed=$pass_count"
echo "NumFailed=$fail_count"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi

exit 0
