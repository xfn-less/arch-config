#!/usr/bin/env python3
"""Telegram 日期排序提醒。账本是同目录 ledger.txt。

用法：11-13 说明  |  +01-01 明年  |  - 说明  |  ls 看表  |  多行覆盖
每天 6:00、18:00（Asia/Shanghai）推一次整表。
"""
import json
import os
import re
import time
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

DIR = Path(__file__).resolve().parent
LEDGER = DIR / "ledger.txt"
STATE = DIR / "state.json"
TZ = ZoneInfo("Asia/Shanghai")
PUSH_HOURS = (6, 18)
API = None


def token():
    env = DIR / ".env"
    if env.exists():
        for line in env.read_text().splitlines():
            line = line.strip()
            if line.startswith("BOT_TOKEN="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    t = os.environ.get("BOT_TOKEN", "").strip()
    if not t:
        raise SystemExit("请设置 BOT_TOKEN（环境变量或 .env）")
    return t


def api(method, **params):
    data = urllib.parse.urlencode({k: v for k, v in params.items() if v is not None}).encode()
    req = urllib.request.Request(API + "/" + method, data=data)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode())


def load_state():
    if STATE.exists():
        return json.loads(STATE.read_text())
    return {"offset": 0, "chat_id": "", "last_push": ""}


def save_state(s):
    STATE.write_text(json.dumps(s, ensure_ascii=False, indent=2))


def parse_line(line):
    m = re.match(r"^(\+)?(\d{1,2})-(\d{1,2})\s+(.+)$", line.strip())
    if not m:
        return None
    plus, mo, d, body = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4).strip()
    md = ("+" if plus else "") + f"{mo:02d}-{d:02d}"
    return md, bool(plus), body


def read_ledger():
    if not LEDGER.exists():
        return []
    items = []
    for line in LEDGER.read_text().splitlines():
        p = parse_line(line)
        if p:
            items.append(p)
    return items


def write_ledger(items):
    LEDGER.write_text("".join(f"{md} {body}\n" for md, _, body in items))


def sort_key(item):
    md, nxt, body = item
    raw = md.lstrip("+")
    a, b = raw.split("-")
    n = int(a) * 100 + int(b)
    return (10000 + n if nxt else n, body)


def build_list():
    today = datetime.now(TZ).strftime("%m-%d")
    ty, tm = map(int, today.split("-"))
    today_key = ty * 100 + tm
    items = sorted(read_ledger(), key=sort_key)
    if not items:
        return ""
    out, done = [], False
    for md, nxt, body in items:
        k = sort_key((md, nxt, body))[0]
        if not done and k >= today_key:
            out.append(today + " ----------------")
            done = True
        out.append(f"{md} {body}")
    if not done:
        out.append(today + " ----------------")
    return "\n".join(out)


def send(chat_id, text):
    if not chat_id or not text:
        return
    print(">> send:\n" + text, flush=True)
    api("sendMessage", chat_id=chat_id, text=text, disable_web_page_preview="true")


def handle(state, text):
    chat = state["chat_id"]
    text = text.strip()
    if text in ("ls", "/ls", "/start"):
        send(chat, build_list() or "空。发一行：11-13 说明")
        return
    m = re.match(r"^-\s+(.+)$", text)
    if m:
        body = m.group(1).strip()
        items = [x for x in read_ledger() if x[2] != body]
        if len(items) == len(read_ledger()):
            send(chat, "没找到")
            return
        write_ledger(items)
        send(chat, build_list() or "空")
        return
    parsed = [x for x in (parse_line(x) for x in text.splitlines()) if x]
    if not parsed:
        send(chat, "格式：11-13 说明\n删：- 说明\n看表：ls")
        return
    if len(parsed) == 1:
        md, nxt, body = parsed[0]
        items = [x for x in read_ledger() if x[2] != body]
        items.append((md, nxt, body))
        write_ledger(items)
    else:
        write_ledger(parsed)
    send(chat, build_list())


def maybe_push(state):
    now = datetime.now(TZ)
    if now.hour not in PUSH_HOURS:
        return
    stamp = now.strftime("%Y-%m-%d-") + str(now.hour)
    if state.get("last_push") == stamp:
        return
    t = build_list()
    if t and state.get("chat_id"):
        send(state["chat_id"], t)
        state["last_push"] = stamp
        save_state(state)
        print("定时推送", stamp, flush=True)


def main():
    global API
    API = "https://api.telegram.org/bot" + token()
    print("清掉 webhook", flush=True)
    print(api("deleteWebhook", drop_pending_updates="true"), flush=True)
    state = load_state()
    print("账本:", LEDGER, "已有", len(read_ledger()), "条", flush=True)
    print("等待消息…", flush=True)
    while True:
        try:
            maybe_push(state)
            r = api("getUpdates", offset=str(state["offset"]), timeout="25")
            for u in r.get("result") or []:
                state["offset"] = u["update_id"] + 1
                save_state(state)
                msg = u.get("message") or {}
                text = msg.get("text")
                cid = str((msg.get("chat") or {}).get("id") or "")
                if not text or not cid:
                    continue
                print("<<", cid, text, flush=True)
                if not state.get("chat_id"):
                    state["chat_id"] = cid
                    save_state(state)
                    print("绑定 chat_id", cid, flush=True)
                elif cid != state["chat_id"]:
                    continue
                handle(state, text)
        except KeyboardInterrupt:
            break
        except Exception as e:
            print("错误:", e, flush=True)
            time.sleep(3)


if __name__ == "__main__":
    main()
