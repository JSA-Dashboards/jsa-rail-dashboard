#!/usr/bin/env bash
# run_refresh.sh: weekly USDA rail data refresh, run by cron on the JSA droplet
# (Tue 08:30 CT, through /opt/alerting/cron-alert). It refetches the USDA AMS
# rail data, overwrites data/rail_data.parquet, and commits + pushes it here.
#
# The LIVE copy is /opt/rail-dashboard/run_refresh.sh, deliberately OUTSIDE
# the clone it updates (/opt/rail-dashboard/repo). The script runs `git pull`
# on that clone, and bash reads a running script incrementally, so a pull that
# rewrote the script mid-run could execute half-old, half-new lines. Edit this
# copy, then copy it to the droplet.
set -euo pipefail

VENV=/opt/rail-dashboard/venv
REPO=/opt/rail-dashboard/repo
LOG=/opt/rail-dashboard/logs/refresh.log

mkdir -p /opt/rail-dashboard/logs

echo "[$(date "+%F %T")] Starting USDA rail data refresh" >> "$LOG"

# Pull latest code
cd "$REPO"
git pull --quiet >> "$LOG" 2>&1

# Fetch from USDA API and overwrite parquet
"$VENV/bin/python" - << 'PYEOF' >> "$LOG" 2>&1
import sys
sys.path.insert(0, '/opt/rail-dashboard/repo')
from pathlib import Path
import usda_api, pandas as pd

print('Fetching from USDA AMS API...')
df = usda_api.load_usda_data()
out = Path('/opt/rail-dashboard/repo/data/rail_data.parquet')
out.parent.mkdir(exist_ok=True)
df.to_parquet(out, index=False)
print(f'Saved {len(df):,} rows  |  {df["Market Year"].max()} week {int(df["MY Week"].max())}')
PYEOF

# Commit and push updated parquet
cd "$REPO"
git config user.email '275148418+koltenpostin93-blip@users.noreply.github.com'
git config user.name 'JSA Droplet'
git add data/rail_data.parquet
if git diff --cached --quiet; then
  echo "[$(date "+%F %T")] No new data, nothing to push" >> "$LOG"
else
  git commit -m "chore: refresh rail parquet $(date +%F)" >> "$LOG" 2>&1
  git push origin main >> "$LOG" 2>&1
  echo "[$(date "+%F %T")] Pushed updated parquet to GitHub" >> "$LOG"
fi

echo "[$(date "+%F %T")] Done" >> "$LOG"
