"""Testes do sync_x_posts.py — sem rede, sem token real: a Scweet é
substituída por um dublê em sys.modules antes do import.

Não existe harness de teste Python neste repo ainda (nem pytest, nem
unittest de outro script) — unittest da stdlib de propósito, pra não
introduzir uma dependência nova só pra isto.

  python scripts/social/test_sync_x_posts.py
"""

import importlib.util
import json
import os
import sys
import tempfile
import types
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]


class _ScweetError(Exception):
    pass


def _install_fake_scweet(calls, responses):
    """Substitui `Scweet`/`Scweet.exceptions` por um dublê ANTES do import do
    script — o mesmo padrão usado pra diagnosticar o bootstrap de CSRF
    (ver histórico do commit `589f4af`)."""

    class AccountPoolExhausted(_ScweetError):
        pass

    class AuthError(_ScweetError):
        pass

    class ManifestError(_ScweetError):
        pass

    class NetworkError(_ScweetError):
        pass

    class ProxyError(_ScweetError):
        pass

    class RateLimitError(_ScweetError):
        pass

    exceptions_mod = types.ModuleType("Scweet.exceptions")
    for name, cls in (
        ("ScweetError", _ScweetError),
        ("AccountPoolExhausted", AccountPoolExhausted),
        ("AuthError", AuthError),
        ("ManifestError", ManifestError),
        ("NetworkError", NetworkError),
        ("ProxyError", ProxyError),
        ("RateLimitError", RateLimitError),
    ):
        setattr(exceptions_mod, name, cls)

    class FakeScweet:
        def __init__(self, **kwargs):
            calls.setdefault("init", []).append(kwargs)

        def get_profile_tweets(self, users, **kwargs):
            calls.setdefault("timeline", []).append(users[0])
            return responses.get(users[0], [])

        def search(self, **kwargs):
            calls.setdefault("search", []).append(kwargs.get("from_users", [None])[0])
            return []

    scweet_mod = types.ModuleType("Scweet")
    scweet_mod.Scweet = FakeScweet
    scweet_mod.exceptions = exceptions_mod
    sys.modules["Scweet"] = scweet_mod
    sys.modules["Scweet.exceptions"] = exceptions_mod


def _load_module():
    spec = importlib.util.spec_from_file_location(
        "sync_x_posts_under_test",
        REPO_ROOT / "scripts" / "social" / "sync_x_posts.py",
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.time.sleep = lambda *_: None  # sem espera real nos testes
    return module


TWEET_GOIAS = {
    "tweet_id": "1",
    "text": "tweet do goias",
    "timestamp": "2026-09-08T10:00:00+00:00",
    "tweet_url": "https://x.com/goiasoficial/status/1",
    "user": {"screen_name": "goiasoficial", "name": "Goiás Esporte Clube"},
}
TWEET_BRAGANTINO = {
    "tweet_id": "2",
    "text": "tweet do bragantino",
    "timestamp": "2026-09-08T11:00:00+00:00",
    "tweet_url": "https://x.com/RedBullBraga/status/2",
    "user": {"screen_name": "RedBullBraga", "name": "Red Bull Bragantino"},
}


class SyncXPostsTest(unittest.TestCase):
    def setUp(self):
        self.calls = {}
        self.responses = {
            "goiasoficial": [TWEET_GOIAS],
            "RedBullBraga": [TWEET_BRAGANTINO],
        }
        _install_fake_scweet(self.calls, self.responses)
        self.module = _load_module()
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        out_dir = Path(self.tmp.name)
        self.module.CLUBS["goias"]["output"] = out_dir / "goias.json"
        self.module.CLUBS["bragantino"]["output"] = out_dir / "bragantino.json"
        os.environ["X_AUTH_TOKEN"] = "fake-token-para-teste"
        self.addCleanup(lambda: os.environ.pop("X_AUTH_TOKEN", None))

    def test_sem_argumentos_preserva_o_comportamento_do_goias(self):
        code = self.module.main([])
        self.assertEqual(code, 0)
        self.assertEqual(self.calls["timeline"], ["goiasoficial"])

    def test_club_bragantino_usa_o_handle_e_arquivo_certos(self):
        code = self.module.main(["--club", "bragantino"])
        self.assertEqual(code, 0)
        self.assertEqual(self.calls["timeline"], ["RedBullBraga"])
        data = json.loads(self.module.CLUBS["bragantino"]["output"].read_text(encoding="utf-8"))
        self.assertEqual(data[0]["user_screen_name"], "RedBullBraga")
        self.assertEqual(data[0]["user_name"], "Red Bull Bragantino")

    def test_cada_clube_grava_so_o_proprio_arquivo(self):
        self.module.main(["--club", "goias"])
        self.module.main(["--club", "bragantino"])
        goias_out = self.module.CLUBS["goias"]["output"]
        braga_out = self.module.CLUBS["bragantino"]["output"]
        self.assertTrue(goias_out.exists())
        self.assertTrue(braga_out.exists())
        goias_data = json.loads(goias_out.read_text(encoding="utf-8"))
        braga_data = json.loads(braga_out.read_text(encoding="utf-8"))
        self.assertEqual(goias_data[0]["user_screen_name"], "goiasoficial")
        self.assertEqual(braga_data[0]["user_screen_name"], "RedBullBraga")
        # Nenhum dado de um clube aparece no arquivo do outro.
        self.assertNotIn("RedBullBraga", json.dumps(goias_data))
        self.assertNotIn("goiasoficial", json.dumps(braga_data))

    def test_club_desconhecido_e_rejeitado_sem_rodar_nada(self):
        with self.assertRaises(SystemExit):
            self.module.main(["--club", "inter"])
        self.assertNotIn("timeline", self.calls)

    def test_vazio_preserva_o_arquivo_ja_salvo_e_falha(self):
        # Simula scrape vazio: sem tweets pro handle do Bragantino.
        self.responses["RedBullBraga"] = []
        out = self.module.CLUBS["bragantino"]["output"]
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps([TWEET_BRAGANTINO]), encoding="utf-8")
        before = out.read_text(encoding="utf-8")

        code = self.module.main(["--club", "bragantino"])

        self.assertEqual(code, 1)
        self.assertEqual(out.read_text(encoding="utf-8"), before)

    def test_sem_x_auth_token_falha_antes_de_qualquer_chamada(self):
        os.environ.pop("X_AUTH_TOKEN", None)
        code = self.module.main(["--club", "bragantino"])
        self.assertEqual(code, 1)
        self.assertNotIn("timeline", self.calls)

    def test_overrides_explicitos_tem_prioridade_sobre_o_registro_clubs(self):
        code = self.module.main(
            [
                "--club",
                "bragantino",
                "--handle",
                "outro_handle",
                "--author-name",
                "Outro Nome",
            ]
        )
        self.assertEqual(code, 1)  # o dublê não tem resposta pra "outro_handle"
        # fetch() tenta a timeline 2x antes de cair pra busca — as duas
        # tentativas usam o handle sobrescrito, nunca o de bragantino/CLUBS.
        self.assertEqual(self.calls["timeline"], ["outro_handle", "outro_handle"])
        self.assertEqual(self.calls["search"], ["outro_handle"])


if __name__ == "__main__":
    unittest.main()
