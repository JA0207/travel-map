#!/bin/bash
# 重新部署足迹地图（保持预览链接有效）
set -e
SRC="/home/sandbox/.openclaw/workspace/travel-map"
WORK="/tmp/deploy_tm"
SKILL="/home/sandbox/.openclaw/workspace/skills/xiaoyi-web-deploy/scripts"

mkdir -p "$WORK"
cp "$SRC/index.html" "$WORK/index.html"
rm -rf "$WORK/maps" "$WORK/vendor"
cp -r "$SRC/maps" "$SRC/vendor" "$WORK/"

cd "$WORK"
rm -f project.zip
zip -r project.zip index.html maps vendor >/dev/null

APP_URL=$(python3 "$SKILL/upload_file.py" "$WORK/project.zip" 2>/dev/null | tail -1)
if [ -z "$APP_URL" ]; then echo "upload failed"; exit 1; fi

python3 - "$APP_URL" <<'PY'
import json, sys
url = sys.argv[1]
cfg = json.load(open('/tmp/deploy_tm/baas-config.json'))
json.dump({"appUrl": url, "apiKey": cfg["apiKey"], "appId": cfg["appId"]}, open('/tmp/deploy_tm/deploy.json', 'w'))
PY

python3 "$SKILL/baas.py" --x-api-type deploy --content-file-path "$WORK/deploy.json" 2>/dev/null | tail -c 300
echo
date "+%Y-%m-%d %H:%M:%S deployed"
