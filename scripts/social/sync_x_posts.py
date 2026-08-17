import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from Scweet import Scweet

HANDLE = "goiasoficial"
LIMIT = 20
DEFAULT_NAME = "Goiás Esporte Clube"
OUTPUT = Path(__file__).resolve().parents[2] / "src" / "social" / "data" / "x_posts.json"
TWITTER_TS = "%a %b %d %H:%M:%S %z %Y"


def to_iso(value):
    if value in (None, ""):
        return None
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value, tz=timezone.utc).isoformat()
    text = str(value)
    parsers = (
        lambda s: datetime.fromisoformat(s.replace("Z", "+00:00")),
        lambda s: datetime.strptime(s, TWITTER_TS),
    )
    for parse in parsers:
        try:
            dt = parse(text)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.astimezone(timezone.utc).isoformat()
        except (ValueError, TypeError):
            continue
    return text


def to_int(value):
    if isinstance(value, bool):
        return 0
    if isinstance(value, (int, float)):
        return int(value)
    if isinstance(value, str):
        try:
            return int(float(value.strip().replace(",", "")))
        except ValueError:
            return 0
    return 0


def pick(tweet, *keys, default=None):
    for key in keys:
        value = tweet.get(key)
        if value not in (None, ""):
            return value
    return default


def author(tweet):
    user = tweet.get("user")
    if isinstance(user, dict):
        return (
            user.get("screen_name") or user.get("username") or HANDLE,
            user.get("name") or DEFAULT_NAME,
        )
    return (
        pick(tweet, "user_screen_name", "username", default=HANDLE),
        pick(tweet, "user_name", "name", default=DEFAULT_NAME),
    )


def images(tweet):
    media = tweet.get("media")
    if isinstance(media, dict) and isinstance(media.get("image_links"), list):
        return [link for link in media["image_links"] if link]
    flat = tweet.get("image_links")
    if isinstance(flat, list):
        return [link for link in flat if link]
    if isinstance(flat, str) and flat:
        return [flat]
    return []


def normalize(tweet):
    screen_name, name = author(tweet)
    return {
        "tweet_id": str(pick(tweet, "tweet_id", "id", default="")),
        "text": pick(tweet, "text", "embedded_text", default=""),
        "timestamp": to_iso(pick(tweet, "timestamp", "created_at", "date")),
        "tweet_url": pick(tweet, "tweet_url", "url", "link", default=""),
        "image_links": images(tweet),
        "user_screen_name": screen_name,
        "user_name": name,
        "likes": to_int(pick(tweet, "likes", default=0)),
        "retweets": to_int(pick(tweet, "retweets", default=0)),
        "comments": to_int(pick(tweet, "comments", "replies", default=0)),
    }


def main():
    token = os.environ.get("X_AUTH_TOKEN")
    if not token:
        print("sync_x_posts: X_AUTH_TOKEN not set", file=sys.stderr)
        return 1

    scweet = Scweet(auth_token=token)
    tweets = scweet.get_profile_tweets([HANDLE], limit=LIMIT, save=False)
    if not isinstance(tweets, list):
        tweets = list(tweets or [])

    posts = [normalize(t) for t in tweets if isinstance(t, dict)]
    posts = [p for p in posts if p["tweet_id"] and p["timestamp"]]
    posts.sort(key=lambda p: p["timestamp"], reverse=True)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(posts, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"sync_x_posts: wrote {len(posts)} posts to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
