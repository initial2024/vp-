#!/usr/bin/env python3
"""Offline configuration sanity checks. Does not execute Xray or VPN."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "configs" / "AL-SSH-TCP-DNS-fixed.json"
cfg = json.loads(path.read_text(encoding="utf-8"))
inbound = cfg["inbounds"][0]
assert inbound["listen"] == "127.0.0.1" and inbound["port"] == 10808
assert inbound["protocol"] == "socks" and inbound["settings"]["udp"] is False
outbounds = cfg["outbounds"]
assert outbounds[0]["tag"] == "AL-SSH" and outbounds[0]["protocol"] == "socks"
socks = outbounds[0]["settings"]["servers"][0]
assert socks == {"address": "127.0.0.1", "port": 1080}
assert outbounds[1]["tag"] == "dns-hijack" and outbounds[1]["protocol"] == "dns"
assert outbounds[2]["tag"] == "block-other-udp" and outbounds[2]["protocol"] == "blackhole"
rules = cfg["routing"]["rules"]
assert rules[0]["type"] == "field" and rules[0]["port"] == "53"
assert set(rules[0]["network"].split(",")) == {"udp", "tcp"}
assert rules[0]["outboundTag"] == "dns-hijack"
assert rules[1]["type"] == "field" and rules[1]["network"] == "udp"
assert rules[1]["outboundTag"] == "block-other-udp"
assert cfg["dns"]["servers"] == ["https://1.1.1.1/dns-query"]
assert cfg["dns"]["queryStrategy"] == "UseIPv4"
assert not any(k in config for config in outbounds for k in ("password", "privateKey"))
print("PASS: JSON 解析、端口、DNS 路由顺序、非 DNS UDP 阻断、无凭证字段")
print("注意：不等于通过 Android / Xray 实际运行验证")
