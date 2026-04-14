# BountyHunt v1.0

> A modular, portable CLI framework for professional bug bounty hunting and authorized security research.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/bash-4.4%2B-green.svg)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Termux-lightgrey.svg)

---

## Overview

BountyHunt is a precision-first security testing framework built for bug bounty hunters and pentesters. The design priority is **accuracy over coverage** — every module implements false-positive reduction before reporting a finding.

**Supported platforms:** Kali Linux, Parrot OS, Ubuntu, Debian, Arch, Fedora, macOS, Termux (Android)

---

## Features

| Module | Technique | FP Reduction |
|--------|-----------|--------------|
| XSS | Unique marker reflection | Exact string match, context-aware, CSP check |
| SQLi | Boolean + time-based | 3-req baseline, 15% threshold, jitter compensation |
| SSRF | Baseline diff | Indicator must be absent from baseline |
| CORS | Multi-origin probe | Wildcard-only → INFO; ACAC required for HIGH |
| GraphQL | Introspection + batching | Schema disclosure, alias abuse, nesting DoS |
| WebSocket | Handshake analysis | Origin validation, plaintext WS, auth check |
| Prototype Pollution | JSON + query string | Server-side probe with unique key reflection |
| MFA Bypass | Flow logic | Rate limit, response manip, race condition |

Additional capabilities:
- **Vulnerability Correlation Engine** — combines findings from multiple modules to elevate severity (e.g. SSRF + cloud metadata → CRITICAL)
- **Central HTTP layer** (`_bh_curl`) — all traffic goes through one function: proxy support, UA rotation, retry on 429, auth headers, logging
- **Scope management** — file-based scope with wildcard, exact, and URL-prefix matching
- **Reports** — Markdown (H1-ready) + HTML (dark mode, sortable table, copy-curl buttons)
- **Notifications** — Telegram / Slack push on CRITICAL/HIGH findings

---

## Installation

```bash
git clone https://github.com/yourhandle/BountyHunt.git
cd BountyHunt
chmod +x bountyhunt.sh
./bountyhunt.sh
```

### Requirements

**Required:** `curl` (present on all supported platforms)

**Optional (enhance results):**
```bash
# Debian / Ubuntu / Kali
sudo apt install bc python3

# macOS
brew install python3

# Termux
pkg install bc python

# WebSocket injection testing
cargo install websocat
```

---

## Usage

### Interactive mode

```bash
./bountyhunt.sh
```

The interactive menu guides through:
1. Target configuration
2. Authentication setup (cookie, bearer, basic, API key)
3. Proxy setup (Burp Suite, mitmproxy)
4. Scope file loading
5. Module selection or full scan

### Quiet mode (scripting)

```bash
BH_QUIET=true ./bountyhunt.sh
```

### Environment variables

```bash
export BH_TARGET="https://target.example.com/api?id=1"
export BH_PROXY="http://127.0.0.1:8080"
export BH_AUTH_HEADER="Authorization: Bearer eyJ..."
export BH_COOKIES="session=abc123"
export BH_OOB_DOMAIN="your.interactsh.com"
```

---

## Configuration

Copy the default config and edit:

```bash
mkdir -p ~/.config/bountyhunt
cp config/bountyhunt.conf ~/.config/bountyhunt/config
```

### Scope file format

One entry per line. Lines starting with `#` are ignored.

```
# Exact domain + all subdomains
example.com

# Wildcard: only subdomains (not root)
*.staging.example.com

# Specific URL prefix
https://api.example.com/v2/

# CIDR range
10.0.0.0/8
```

Load from the menu: **[4] Scope Manager → [1] Load from file**

---

## Examples

### Single module test

```bash
# Set target and run XSS scan
./bountyhunt.sh
# [1] Set Target → https://example.com/search?q=test
# [10] XSS
```

### Full web scan with proxy

```bash
export BH_PROXY="http://127.0.0.1:8080"
export BH_TARGET="https://example.com"
./bountyhunt.sh
# [A] Full Web Scan
```

### Authenticated scan

```bash
./bountyhunt.sh
# [1] Set Target
# [2] Auth Setup → [3] Bearer Token → paste token
# [A] Full Web Scan
```

### Report generation

Reports are generated automatically after a full scan, or manually via **[R]**.

```
~/bountyhunt_results/
└── example.com/
    ├── example.com_20250601_143022.md    # Markdown (paste to H1)
    ├── example.com_20250601_143022.html  # HTML (open in browser)
    ├── findings.log                      # Raw findings log
    └── http.log                          # HTTP traffic log (if --log enabled)
```

---

## Architecture

```
BountyHunt/
├── bountyhunt.sh          # Entry point, module loader, main loop
├── core/
│   ├── colors.sh          # Terminal colors and formatters
│   ├── config.sh          # OS detection, platform config, global state
│   ├── logger.sh          # Finding engine, severity logging, deduplication
│   ├── network.sh         # _bh_curl() central HTTP layer
│   ├── scope.sh           # Scope file parser and _in_scope() validator
│   ├── signals.sh         # Signal handlers, spinner, progress bar
│   ├── target.sh          # Target setter, auth, proxy, session history
│   ├── banner.sh          # ASCII banner and interactive menu
│   └── scanner.sh         # Full scan orchestrator
├── modules/
│   ├── xss.sh             # XSS with unique marker verification
│   ├── sqli.sh            # SQLi boolean + time-based with jitter comp.
│   ├── ssrf.sh            # SSRF with baseline diff
│   ├── cors.sh            # CORS with context-aware severity
│   ├── graphql.sh         # GraphQL introspection, batch, nesting, IDOR
│   ├── websocket.sh       # WebSocket handshake and injection
│   ├── prototype.sh       # Prototype Pollution server + client check
│   └── mfa.sh             # MFA/2FA bypass logic testing
├── lib/
│   ├── correlation.sh     # Cross-module finding correlation engine
│   └── report.sh          # Markdown + HTML report generation
├── config/
│   └── bountyhunt.conf    # Default configuration template
└── reports/               # Generated reports (gitignored)
```

---

## False Positive Reduction

Each module implements specific countermeasures:

**XSS:** Reflection uses a unique per-test marker (`BH<hex>`). The test checks for the complete `<bh-xss-MARKER>` tag verbatim. Reflections inside HTML comments or behind a blocking CSP are downgraded to LOW.

**SQLi Boolean:** Establishes a 3-request baseline, calculates natural variance, then requires the true/false payload diff to exceed `max(15%, 3×stddev)` AND the MD5 of normalized bodies (CSRF tokens stripped) to differ.

**SQLi Time-based:** Measures network jitter before testing. If jitter > 1500ms, test is skipped as unreliable. Uses an adaptive threshold and verifies linearity (measured time must be ≥ 80% of expected sleep time).

**SSRF:** Each cloud/system indicator is checked in the payload response and verified to be **absent** from the baseline response. DNS-only callbacks are logged as INFO, not HIGH.

**CORS:** Wildcard `*` without credentials is reported as INFO (browsers block credentials + wildcard; this is not exploitable). Only arbitrary origin + `ACAC: true` is CRITICAL.

---

## Roadmap

- [ ] SSTI detection (Jinja2, Twig, FreeMarker templates)
- [ ] JWT signature bypass (alg:none, secret brute)
- [ ] HTTP request smuggling (CL.TE / TE.CL)
- [ ] OAuth 2.0 flow auditing
- [ ] Subdomain enumeration (passive + active)
- [ ] Nuclei integration (template-based scanning)
- [ ] Rate limit bypass techniques
- [ ] Cache poisoning detection
- [ ] IDOR enumeration via sequential ID bruteforce

---

## Legal

Use only on targets you have **explicit written authorization** to test.

See [DISCLAIMER.md](DISCLAIMER.md) for full legal terms.

---

## License

MIT — see [LICENSE](LICENSE)
