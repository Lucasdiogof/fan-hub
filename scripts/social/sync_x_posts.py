import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from Scweet import Scweet
from Scweet.exceptions import (
    AuthError,
    ManifestError,
    NetworkError,
    ProxyError,
    RateLimitError,
    ScweetError,
)

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


def log(message):
    print(f"sync_x_posts: {message}", file=sys.stderr, flush=True)


# Por que um scrape volta vazio importa mais que o fato de ter voltado vazio:
# token morto, rate limit e bloqueio de rede pedem ações completamente
# diferentes. A Scweet distingue os casos com exceções próprias — antes tudo
# caía no mesmo "0 posts" sem explicação, e a investigação virava chute.
DIAGNOSIS = [
    (AuthError, "o auth_token foi recusado (401/403) — sessão do X expirada ou revogada"),
    (RateLimitError, "o X respondeu 429 — rate limit, adianta esperar e tentar depois"),
    (ProxyError, "falha no proxy configurado em X_PROXY"),
    (NetworkError, "falha de rede/conectividade — combina com bloqueio do X ao IP do runner"),
    (ManifestError, "o manifesto de queries do X não pôde ser carregado"),
]


def describe(exc):
    for kind, explanation in DIAGNOSIS:
        if isinstance(exc, kind):
            return f"{type(exc).__name__}: {explanation}"
    return f"{type(exc).__name__}: {exc}"


def make_client(token):
    """Cliente da Scweet, tentando renovar o manifesto de queries do X.

    O manifesto guarda os ids das queries GraphQL do X. Quando o X troca os
    endpoints, o manifesto embutido na versão instalada fica velho e a
    raspagem passa a devolver ZERO sem erro nenhum — que é exatamente o
    sintoma. Renovar na inicialização cobre esse caso; se a renovação em si
    falhar, cair pro embutido é melhor que não rodar.
    """
    # `X_PROXY` fica vazio por padrão: só existe porque, se a hipótese de
    # bloqueio por IP de datacenter se confirmar, sair do IP do runner passa
    # a ser questão de definir um secret, sem mexer em código.
    proxy = os.environ.get("X_PROXY") or None
    if proxy:
        log("usando proxy de X_PROXY")

    try:
        return Scweet(auth_token=token, proxy=proxy, manifest_scrape_on_init=True)
    except ScweetError as exc:
        log(f"manifesto novo falhou ({describe(exc)}); usando o embutido")
        return Scweet(auth_token=token, proxy=proxy, manifest_scrape_on_init=False)


def fetch(scweet):
    """Timeline com uma segunda tentativa; se ainda vier vazio, busca 'Latest'.

    São dois caminhos diferentes pro mesmo dado no X — quando um está
    quebrado, o outro às vezes ainda responde.
    """
    for attempt in (1, 2):
        try:
            tweets = scweet.get_profile_tweets(
                [HANDLE], limit=LIMIT, max_empty_pages=2, save=False
            )
            if tweets:
                return list(tweets)
            log(f"timeline devolveu 0 posts (tentativa {attempt}/2)")
        except ScweetError as exc:
            log(f"timeline falhou (tentativa {attempt}/2) — {describe(exc)}")
        if attempt == 1:
            time.sleep(3)

    try:
        log("tentando a busca 'Latest' como alternativa")
        tweets = scweet.search(
            from_users=[HANDLE],
            display_type="Latest",
            limit=LIMIT,
            max_empty_pages=2,
            save=False,
        )
        if tweets:
            return list(tweets)
        log("a busca 'Latest' também devolveu 0 posts")
    except ScweetError as exc:
        log(f"busca 'Latest' falhou — {describe(exc)}")

    return []


def main():
    token = os.environ.get("X_AUTH_TOKEN")
    if not token:
        log("X_AUTH_TOKEN não definido")
        return 1

    tweets = fetch(make_client(token))

    posts = [normalize(t) for t in tweets if isinstance(t, dict)]
    posts = [p for p in posts if p["tweet_id"] and p["timestamp"]]
    posts.sort(key=lambda p: p["timestamp"], reverse=True)

    # Vazio NUNCA sobrescreve o que já está salvo, e NUNCA vira sucesso: o
    # job existe pra garantir que o feed atualiza, então o Actions tem que
    # ficar vermelho. Preservar os posts antigos é o certo; esconder a falha
    # atrás de um check verde só faria a investigação começar tarde.
    if not posts:
        existing = []
        if OUTPUT.exists():
            try:
                existing = json.loads(OUTPUT.read_text(encoding="utf-8")) or []
            except (ValueError, OSError):
                existing = []
        if existing:
            log(f"0 posts raspados; mantendo os {len(existing)} já salvos")
        else:
            log("0 posts raspados e não há feed salvo pra preservar")
        return 1

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(posts, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"sync_x_posts: wrote {len(posts)} posts to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
