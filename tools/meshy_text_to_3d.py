#!/usr/bin/env python3
"""Generate a textured GLB from Meshy text-to-3d (preview + refine).

Reads MESHY_API_KEY from the environment. Falls back to Meshy's documented
test-mode key so local playtest can run without a dashboard key.

Usage:
  python tools/meshy_text_to_3d.py --name truck --out "assets/models/farm/truck.glb" \\
      --prompt "a red farm pickup truck" --texture "dusty red paint, chrome bumper"
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://api.meshy.ai/openapi/v2/text-to-3d"
TEST_KEY = "msy_dummy_api_key_for_test_mode_12345678"


def _headers() -> dict:
    key = os.environ.get("MESHY_API_KEY", "").strip() or TEST_KEY
    return {
        "Authorization": "Bearer %s" % key,
        "Content-Type": "application/json",
    }


def _request(method: str, url: str, payload: dict | None = None) -> dict:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=_headers(), method=method)
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit("Meshy %s %s -> HTTP %s\n%s" % (method, url, exc.code, body)) from exc


def _poll(task_id: str, label: str) -> dict:
    url = "%s/%s" % (API, task_id)
    while True:
        task = _request("GET", url)
        status = str(task.get("status", "?"))
        progress = task.get("progress", 0)
        print("%s %s %s%%" % (label, status, progress), flush=True)
        if status == "SUCCEEDED":
            return task
        if status in ("FAILED", "CANCELED"):
            err = task.get("task_error") or {}
            raise SystemExit("%s failed: %s" % (label, err.get("message", task)))
        time.sleep(8)


def _download(url: str, dest: str) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(dest)), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "livias-stable/meshy"})
    with urllib.request.urlopen(req, timeout=180) as resp, open(dest, "wb") as out:
        out.write(resp.read())
    print("saved %s (%d bytes)" % (dest, os.path.getsize(dest)), flush=True)


def generate(prompt: str, texture: str, dest: str, name: str) -> None:
    preview = _request(
        "POST",
        API,
        {
            "mode": "preview",
            "prompt": prompt,
            "ai_model": "latest",
            "should_remesh": True,
            "target_polycount": 12000,
            "target_formats": ["glb"],
            "auto_size": True,
            "origin_at": "bottom",
        },
    )
    preview_id = preview.get("result")
    if not preview_id:
        raise SystemExit("no preview task id: %s" % preview)
    print("%s preview %s" % (name, preview_id), flush=True)
    _poll(preview_id, "%s preview" % name)

    refine = _request(
        "POST",
        API,
        {
            "mode": "refine",
            "preview_task_id": preview_id,
            "enable_pbr": True,
            "texture_prompt": texture or prompt,
            "texture_resolution": "2k",
            "target_formats": ["glb"],
            "auto_size": True,
            "origin_at": "bottom",
        },
    )
    refine_id = refine.get("result")
    if not refine_id:
        raise SystemExit("no refine task id: %s" % refine)
    print("%s refine %s" % (name, refine_id), flush=True)
    done = _poll(refine_id, "%s refine" % name)
    urls = done.get("model_urls") or {}
    glb = urls.get("glb")
    if not glb:
        raise SystemExit("no glb url: %s" % done)
    _download(glb, dest)
    thumb = done.get("thumbnail_url")
    if thumb:
        _download(thumb, os.path.splitext(dest)[0] + "_thumb.png")
    # Test-mode dummy key always returns the same sample mug.
    if os.path.getsize(dest) == 1956776:
        raise SystemExit(
            "Meshy returned the test-mode sample mug, not %s. "
            "Set MESHY_API_KEY to a real key from https://www.meshy.ai/settings/api"
            % name
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", required=True)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--texture", default="")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    generate(args.prompt, args.texture, args.out, args.name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
