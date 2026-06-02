#!/usr/bin/env python3
"""Inspect Firefox's LIVE chrome DOM over Marionette (chrome context).

Connects to a Firefox started with `--marionette` and queries the actual
rendered browser-UI document (browser.xhtml) — the thing userChrome targets.
Returns runtime truth the static source can't give: computed styles (who won
the cascade), runtime state attributes ([open]/[focused]/...), shadow DOM.

Usage (normally invoked by firefox-live.sh, which launches Firefox first):
  inspect.py --id nav-bar
  inspect.py --selector "#urlbar .urlbar-background" --computed background-color,border
  inspect.py --id back-button --html --children
"""
import argparse, json, sys, time

try:
    from marionette_driver.marionette import Marionette
except ImportError:
    sys.exit("error: marionette_driver not installed (firefox-live.sh provisions a venv)")


def connect(port, timeout=40):
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        try:
            m = Marionette(host="127.0.0.1", port=port, socket_timeout=10)
            m.start_session()
            return m
        except Exception as e:  # noqa: BLE001 - retry any startup race
            last = e
            time.sleep(1)
    sys.exit(f"error: could not connect to marionette on 127.0.0.1:{port}: {last}")


JS = r"""
const arg = arguments[0];
let el = null;
if (arg.selector) el = document.querySelector(arg.selector);
else if (arg.id) el = document.getElementById(arg.id);
if (!el) return { found: false };
const cs = getComputedStyle(el);
const props = (arg.computed && arg.computed.length)
  ? arg.computed
  : ["background-color", "color", "border", "display", "visibility", "opacity"];
const computed = {};
for (const p of props) computed[p] = cs.getPropertyValue(p);
const out = {
  found: true,
  tag: el.localName,
  id: el.id || null,
  classes: [...el.classList],
  attrs: Object.fromEntries([...el.attributes].map(a => [a.name, a.value])),
  computed,
};
if (arg.html) out.html = el.outerHTML.slice(0, 1500);
if (arg.children) out.children = [...el.children].map(c => ({
  tag: c.localName, id: c.id || null, classes: [...c.classList],
}));
if (arg.shadow) out.shadow = el.shadowRoot ? el.shadowRoot.innerHTML.slice(0, 1500) : null;
return out;
"""


def main():
    ap = argparse.ArgumentParser(description="Inspect live Firefox chrome DOM via Marionette")
    ap.add_argument("--port", type=int, default=2828)
    ap.add_argument("--id", help="element id (getElementById)")
    ap.add_argument("--selector", help="CSS selector (querySelector)")
    ap.add_argument("--computed", default="", help="comma list of computed props to read")
    ap.add_argument("--html", action="store_true", help="include outerHTML snippet")
    ap.add_argument("--children", action="store_true", help="list direct children")
    ap.add_argument("--shadow", action="store_true", help="include shadowRoot innerHTML if any")
    a = ap.parse_args()

    if not a.id and not a.selector:
        sys.exit("error: provide --id or --selector")

    m = connect(a.port)
    try:
        m.set_context(m.CONTEXT_CHROME)
        arg = {
            "id": a.id,
            "selector": a.selector,
            "computed": [s.strip() for s in a.computed.split(",") if s.strip()],
            "html": a.html,
            "children": a.children,
            "shadow": a.shadow,
        }
        res = m.execute_script(JS, script_args=[arg], sandbox="system")
        print(json.dumps(res, indent=2))
        if isinstance(res, dict) and not res.get("found"):
            sys.exit(2)  # not found -> nonzero for scripting
    finally:
        try:
            m.delete_session()
        except Exception:  # noqa: BLE001
            pass


if __name__ == "__main__":
    main()
