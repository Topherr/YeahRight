"""Keep the TOC's ## Interface line in step with Blizzard's live clients.

Reads each product's current client version from Blizzard's public version
service, converts it to an interface number (12.1.0 -> 120100, 1.60.1 ->
16001) and, if the TOC differs, rewrites the TOC and README and bumps the
patch version. Prints "changed=true|false" for the workflow.
"""

import os
import re
import sys
import urllib.request

TOC = "YeahRight.toc"
README = "README.txt"
REGION = "us"


def client_version(product):
    url = f"https://{REGION}.version.battle.net/v2/products/{product}/versions"
    with urllib.request.urlopen(url, timeout=30) as response:
        lines = response.read().decode().splitlines()

    header = next(line for line in lines if line.startswith("Region!"))
    columns = [column.split("!")[0] for column in header.split("|")]
    for line in lines:
        row = dict(zip(columns, line.split("|")))
        if row.get("Region") == REGION:
            return row["VersionsName"]

    sys.exit(f"{product}: no {REGION} version listed; update PRODUCTS in the workflow")


def interface_number(version):
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)\.\d+", version)
    if not match:
        sys.exit(f"unexpected client version format: {version!r}")
    major, minor, patch = map(int, match.groups())
    return major * 10000 + minor * 100 + patch


def main():
    products = os.environ["PRODUCTS"].split()
    versions = {product: client_version(product) for product in products}
    wanted = list(dict.fromkeys(interface_number(v) for v in versions.values()))
    for product, version in versions.items():
        print(f"{product}: {version} -> {interface_number(version)}", file=sys.stderr)

    with open(TOC) as f:
        toc = f.read()
    current = re.search(r"^## Interface:\s*(.+)$", toc, re.M).group(1)
    if {int(n) for n in current.split(",")} == set(wanted):
        print("changed=false")
        return

    interfaces = ", ".join(map(str, wanted))
    old_version = re.search(r"^## Version:\s*(\S+)", toc, re.M).group(1)
    major, minor, patch, suffix = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)(.*)", old_version).groups()
    new_version = f"{major}.{minor}.{int(patch) + 1}{suffix}"

    toc = re.sub(r"^## Interface:.*$", f"## Interface: {interfaces}", toc, count=1, flags=re.M)
    toc = re.sub(r"^## Version:.*$", f"## Version: {new_version}", toc, count=1, flags=re.M)
    with open(TOC, "w") as f:
        f.write(toc)

    clients = ", ".join(versions.values())
    with open(README) as f:
        readme = f.read()
    readme = readme.replace(f"Version {old_version}\n", f"Version {new_version}\n", 1)
    readme = readme.replace(
        "VERSION HISTORY\n---------------\n",
        "VERSION HISTORY\n---------------\n"
        f"{new_version}\n"
        f"- Updated the TOC interface to {interfaces} for clients {clients}.\n\n",
        1,
    )
    with open(README, "w") as f:
        f.write(readme)

    print(f"TOC interface {current} -> {interfaces}; version {new_version}", file=sys.stderr)
    print("changed=true")
    print(f"version={new_version}")
    print(f"interfaces={interfaces}")


if __name__ == "__main__":
    main()
