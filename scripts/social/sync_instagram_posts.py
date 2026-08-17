import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import instaloader

HANDLE = "goiasoficial"
LIMIT = 20
OUTPUT = Path(__file__).resolve().parents[2] / "src" / "social" / "data" / "instagram_posts.json"
RATE_LIMIT_HINTS = ("401", "403", "429", "login", "challenge", "redirect", "wait", "rate", "temporarily")


def log(event):
    print(f"instagram.sync.{event}")


def to_iso(value):
    if not isinstance(value, datetime):
        return None
    dt = value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def media_type(post):
    if getattr(post, "typename", "") == "GraphSidecar":
        return "carousel"
    if getattr(post, "is_video", False):
        return "video"
    return "image"


def normalize(post):
    return {
        "shortcode": post.shortcode,
        "caption": post.caption or "",
        "timestamp": to_iso(getattr(post, "date_utc", None)),
        "permalink": f"https://www.instagram.com/p/{post.shortcode}/",
        "media_type": media_type(post),
        "image_url": getattr(post, "url", "") or "",
    }


def load_existing_items():
    try:
        data = json.loads(OUTPUT.read_text(encoding="utf-8"))
        return data.get("items", [])
    except (FileNotFoundError, ValueError):
        return None


def classify_failure(error):
    text = str(error).lower()
    return "rate_limited" if any(hint in text for hint in RATE_LIMIT_HINTS) else "failed"


def build_loader():
    loader = instaloader.Instaloader(
        download_pictures=False,
        download_videos=False,
        download_video_thumbnails=False,
        download_geotags=False,
        download_comments=False,
        save_metadata=False,
        compress_json=False,
        quiet=True,
        max_connection_attempts=1,
    )
    sessionid = (os.environ.get("INSTAGRAM_SESSIONID") or os.environ.get("INSTAGRAM_SESSION") or "").strip()
    if sessionid:
        loader.context._session.cookies.set("sessionid", sessionid, domain=".instagram.com")
        username = loader.context.test_login()
        if not username:
            raise RuntimeError("INSTAGRAM_SESSIONID invalid or expired")
        loader.context.username = username
        log("authenticated")
    else:
        log("anonymous")
    return loader


def fetch_items():
    loader = build_loader()
    profile = instaloader.Profile.from_username(loader.context, HANDLE)

    items = []
    for post in profile.get_posts():
        item = normalize(post)
        if item["shortcode"] and item["timestamp"]:
            items.append(item)
        if len(items) >= LIMIT:
            break
    return items


def main():
    log("started")
    try:
        items = fetch_items()
    except Exception as error:  # noqa: BLE001
        reason = classify_failure(error)
        log(reason)
        print(f"instagram.sync.error: {type(error).__name__}: {error}", file=sys.stderr)
        return 1

    if not items:
        log("rate_limited")
        print("instagram.sync.error: no posts returned (likely blocked)", file=sys.stderr)
        return 1

    items.sort(key=lambda item: item["timestamp"], reverse=True)

    if items == load_existing_items():
        log("no_changes")
        return 0

    payload = {
        "generatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "items": items,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    log("success")
    print(f"instagram.sync: wrote {len(items)} posts to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
