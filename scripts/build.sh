#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sdk_dir="${GARMIN_SDK_HOME:-}"

if [[ -z "$sdk_dir" && -f "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg" ]]; then
    sdk_dir="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
fi

if [[ -n "$sdk_dir" ]]; then
    compiler="$sdk_dir/bin/monkeyc"
else
    compiler="$(command -v monkeyc || true)"
fi

if [[ -z "$compiler" || ! -x "$compiler" ]]; then
    echo "Connect IQ compiler not found. Install the SDK or set GARMIN_SDK_HOME." >&2
    exit 1
fi

key="${GARMIN_DEVELOPER_KEY:-}"
if [[ -z "$key" || ! -f "$key" ]]; then
    echo "Set GARMIN_DEVELOPER_KEY to your Garmin developer signing key." >&2
    exit 1
fi

mkdir -p "$project_dir/bin"
cd "$project_dir"
"$compiler" -f monkey.jungle -o bin/AIRFLD.PRG -d venu445mm -y "$key" -r -w
echo "Built $project_dir/bin/AIRFLD.PRG"
