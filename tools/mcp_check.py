#!/usr/bin/env python3
"""Comprueba que los servidores MCP compartidos (.mcp.json) arrancan y responden.

Uso:
    python tools/mcp_check.py            # handshake MCP + tools/list de cada servidor
    python tools/mcp_check.py --smoke    # además: Playwright abre el sitio en vivo y
                                         # GitHub lista los PRs del repositorio
    python tools/mcp_check.py --json

Solo biblioteca estándar. Los valores ``${VAR}`` de las cabeceras se expanden
desde el entorno (p. ej. ``GITHUB_PERSONAL_ACCESS_TOKEN``) y nunca se imprimen.
"""

from __future__ import annotations

import argparse
import json
import os
import queue
import re
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / ".mcp.json"
PROTOCOL = "2025-06-18"
SITE = "https://judysimulator.wuaze.com"
REPO_OWNER, REPO_NAME = "zimmercanoa", "judy-simulator-orca"
TOKEN_RE = re.compile(r"(gh[opsur]_|github_pat_)[A-Za-z0-9_]+")


def mask(text: str) -> str:
    return TOKEN_RE.sub(r"\1****", str(text))


def expand(value: str) -> str:
    return re.sub(r"\$\{(\w+)\}", lambda m: os.environ.get(m.group(1), ""), value)


def init_msg(i: int) -> dict:
    return {
        "jsonrpc": "2.0", "id": i, "method": "initialize",
        "params": {
            "protocolVersion": PROTOCOL, "capabilities": {},
            "clientInfo": {"name": "judy-mcp-check", "version": "1.0"},
        },
    }


class Stdio:
    def __init__(self, command: str, args: list[str]):
        argv = [command, *args]
        if os.name != "nt" and command.lower() == "cmd" and args[:1] == ["/c"]:
            argv = args[1:]  # .mcp.json usa "cmd /c" para Windows
        self.proc = subprocess.Popen(
            argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, cwd=ROOT,
        )
        self.lines: queue.Queue = queue.Queue()
        threading.Thread(target=self._read, daemon=True).start()
        self.next_id = 1

    def _read(self):
        for raw in self.proc.stdout:
            self.lines.put(raw)

    def request(self, method: str, params: dict | None = None, timeout: float = 120) -> dict:
        i = self.next_id
        self.next_id += 1
        msg = init_msg(i) if method == "initialize" else {
            "jsonrpc": "2.0", "id": i, "method": method, "params": params or {}}
        self._send(msg)
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                raw = self.lines.get(timeout=1)
            except queue.Empty:
                if self.proc.poll() is not None:
                    raise RuntimeError(f"el proceso terminó (código {self.proc.returncode})")
                continue
            try:
                data = json.loads(raw)
            except ValueError:
                continue
            if data.get("id") == i:
                if "error" in data:
                    raise RuntimeError(mask(data["error"]))
                if method == "initialize":
                    self._send({"jsonrpc": "2.0", "method": "notifications/initialized"})
                return data["result"]
        raise TimeoutError(f"{method}: sin respuesta en {timeout:.0f}s")

    def _send(self, msg: dict):
        self.proc.stdin.write((json.dumps(msg) + "\n").encode())
        self.proc.stdin.flush()

    def close(self):
        try:
            self.proc.stdin.close()
        except OSError:
            pass
        if os.name == "nt":  # cmd /c deja hijos vivos: matar el árbol
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(self.proc.pid)],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            self.proc.kill()


class Http:
    def __init__(self, url: str, headers: dict[str, str]):
        self.url = url
        self.headers = {k: expand(v) for k, v in headers.items()}
        auth = self.headers.get("Authorization", "")
        if auth.strip() in {"", "Bearer"}:
            missing = re.findall(r"\$\{(\w+)\}", headers.get("Authorization", ""))
            raise RuntimeError(f"falta la variable de entorno {', '.join(missing) or 'del token'}")
        self.session = None
        self.next_id = 1

    def request(self, method: str, params: dict | None = None, timeout: float = 60) -> dict:
        i = self.next_id
        self.next_id += 1
        msg = init_msg(i) if method == "initialize" else {
            "jsonrpc": "2.0", "id": i, "method": method, "params": params or {}}
        data = self._post(msg, timeout)
        if method == "initialize":
            self._post({"jsonrpc": "2.0", "method": "notifications/initialized"}, timeout)
        return data

    def _post(self, msg: dict, timeout: float):
        headers = {
            **self.headers, "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
            "MCP-Protocol-Version": PROTOCOL,
        }
        if self.session:
            headers["Mcp-Session-Id"] = self.session
        req = urllib.request.Request(self.url, json.dumps(msg).encode(), headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                self.session = resp.headers.get("Mcp-Session-Id") or self.session
                body = resp.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as exc:
            raise RuntimeError(f"HTTP {exc.code}: {mask(exc.read()[:200].decode('utf-8', 'replace'))}")
        if "id" not in msg:
            return None
        for chunk in [body] + [l[5:] for l in body.splitlines() if l.startswith("data:")]:
            try:
                data = json.loads(chunk)
            except ValueError:
                continue
            if data.get("id") == msg["id"]:
                if "error" in data:
                    raise RuntimeError(mask(data["error"]))
                return data["result"]
        raise RuntimeError("respuesta MCP no reconocida")

    def close(self):
        pass


def text_of(result: dict) -> str:
    return "\n".join(c.get("text", "") for c in result.get("content", []) if c.get("type") == "text")


def smoke(name: str, client) -> str:
    if name == "playwright":
        client.request("tools/call", {"name": "browser_navigate", "arguments": {"url": SITE}}, 120)
        title = ""
        for _ in range(10):  # el desafío aes.js recarga la página
            res = client.request("tools/call", {"name": "browser_evaluate",
                                                "arguments": {"function": "() => document.title"}}, 60)
            title = text_of(res)
            m = re.search(r'"([^"]*)"', title)
            title = m.group(1) if m else title.strip()
            if title and "slowAES" not in title:
                break
            time.sleep(2)
        if not title:
            raise RuntimeError("no se obtuvo el título")
        return f"título de {SITE}: {title!r}"
    if name == "github":
        res = client.request("tools/call", {"name": "list_pull_requests", "arguments": {
            "owner": REPO_OWNER, "repo": REPO_NAME, "state": "all", "perPage": 5}}, 60)
        if res.get("isError"):
            raise RuntimeError(mask(text_of(res))[:200])
        prs = json.loads(text_of(res) or "[]")
        if isinstance(prs, dict):
            prs = prs.get("pull_requests") or prs.get("items") or []
        resumen = ", ".join(f"#{p.get('number')} {p.get('state')}" for p in prs[:5])
        return f"PRs de {REPO_OWNER}/{REPO_NAME}: {len(prs)} ({resumen})"
    if name == "context7":
        res = client.request("tools/call", {"name": "resolve-library-id",
                                            "arguments": {"libraryName": "flutter", "query": "flutter"}}, 60)
        if res.get("isError"):
            raise RuntimeError(text_of(res)[:200])
        return "resolve-library-id('flutter') respondió"
    return ""


def check(name: str, spec: dict, do_smoke: bool) -> dict:
    out = {"server": name, "ok": False}
    client = None
    try:
        if spec.get("type", "stdio") == "http":
            client = Http(spec["url"], spec.get("headers", {}))
        else:
            client = Stdio(spec["command"], spec.get("args", []))
        info = client.request("initialize", timeout=180)
        out["serverInfo"] = info.get("serverInfo", {})
        tools = client.request("tools/list").get("tools", [])
        out["tools"] = len(tools)
        if do_smoke:
            out["smoke"] = smoke(name, client)
        out["ok"] = True
    except Exception as exc:  # noqa: BLE001 - se informa por servidor
        out["error"] = mask(exc)
    finally:
        if client:
            client.close()
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--smoke", action="store_true", help="pruebas funcionales en vivo")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("servers", nargs="*", help="limitar a estos servidores")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    servers = json.loads(CONFIG.read_text(encoding="utf-8"))["mcpServers"]
    results = [check(n, s, args.smoke) for n, s in servers.items()
               if not args.servers or n in args.servers]
    if args.json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
    else:
        for r in results:
            if r["ok"]:
                si = r.get("serverInfo", {})
                print(f"OK    {r['server']}: {si.get('name', '?')} {si.get('version', '')}, {r['tools']} tools")
                if r.get("smoke"):
                    print(f"      {r['smoke']}")
            else:
                print(f"FALLO {r['server']}: {r['error']}")
    return 0 if all(r["ok"] for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
