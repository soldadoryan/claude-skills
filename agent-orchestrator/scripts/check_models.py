#!/usr/bin/env python3
"""Verifica se existem modelos Claude mais novos do que os do registro (models.json).

Uso:  python3 scripts/check_models.py
Saída (primeira linha):
  STATUS: up_to_date     -> nada novo
  STATUS: new_models     -> seguido de uma linha por modelo novo: "NEW <id> (<motivo>)"
  STATUS: check_failed   -> não foi possível consultar nenhuma fonte (sem rede, etc.)

Só consulta fontes oficiais da Anthropic. Não altera nada: adicionar um modelo
é decisão do usuário (ver seção "Verificação de modelos novos" do SKILL.md).
"""
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
REGISTRY = SKILL_DIR / "models.json"

DOC_SOURCES = [
    "https://platform.claude.com/docs/en/about-claude/models/overview.md",
    "https://platform.claude.com/docs/en/about-claude/models/overview",
    "https://code.claude.com/docs/en/model-config.md",
]
MODEL_RE = re.compile(r"\bclaude-([a-z]+)-(\d+(?:-\d+)*)")


def parse(model_id):
    m = MODEL_RE.match(model_id)
    if not m:
        return None
    family = m.group(1)
    # descarta sufixo de data (8 dígitos) para comparar só a versão
    version = tuple(int(p) for p in m.group(2).split("-") if len(p) < 8)
    if not version:
        return None
    return family, version


def canonical(model_id):
    """claude-haiku-4-5-20251001 -> claude-haiku-4-5"""
    parsed = parse(model_id)
    if not parsed:
        return model_id
    family, version = parsed
    return "claude-%s-%s" % (family, "-".join(str(v) for v in version))


def fetch(url, headers=None, timeout=8):
    req = urllib.request.Request(url, headers={"User-Agent": "agent-orchestrator-skill", **(headers or {})})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")


def collect_ids():
    found, ok = set(), False
    key = os.environ.get("ANTHROPIC_API_KEY")
    if key:
        try:
            data = json.loads(fetch("https://api.anthropic.com/v1/models?limit=100",
                                    {"x-api-key": key, "anthropic-version": "2023-06-01"}))
            found.update(m["id"] for m in data.get("data", []))
            ok = True
        except Exception:
            pass
    for url in DOC_SOURCES:
        try:
            text = fetch(url)
        except Exception:
            continue
        ok = True
        found.update(m.group(0) for m in MODEL_RE.finditer(text))
    return found, ok


def main():
    registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    best = {}
    for m in registry["models"]:
        p = parse(m["id"])
        if p:
            best[p[0]] = max(best.get(p[0], ()), p[1])
    known = {canonical(m["id"]) for m in registry["models"]}
    dismissed = {canonical(d) for d in registry.get("dismissed", [])}

    ids, ok = collect_ids()
    if not ok:
        print("STATUS: check_failed")
        return 0

    new = {}
    for mid in ids:
        p = parse(mid)
        if not p:
            continue
        family, version = p
        cid = canonical(mid)
        if cid in known or cid in dismissed:
            continue
        if family not in best:
            new[cid] = "família nova"
        elif version > best[family]:
            new[cid] = "mais novo que %s atual" % family

    if not new:
        print("STATUS: up_to_date")
    else:
        print("STATUS: new_models")
        for cid in sorted(new):
            print("NEW %s (%s)" % (cid, new[cid]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
