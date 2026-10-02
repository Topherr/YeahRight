"""Print the CurseForge upload metadata JSON for the current TOC version.

Game versions are matched by name to the TOC's interface numbers
(120100 -> "12.1.0", 16001 -> "1.60.1"). Interfaces CurseForge doesn't list
yet are skipped with a warning; the upload fails only if none match.
"""

import json
import os
import re
import sys
import urllib.request

TOC = "YeahRight.toc"
README = "README.txt"
API = "https://wow.curseforge.com/api"


def fetch_game_versions(token):
    request = urllib.request.Request(f"{API}/game/versions", headers={"X-Api-Token": token})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def interface_to_name(interface):
    return f"{interface // 10000}.{interface // 100 % 100}.{interface % 100}"


def game_version_ids(interfaces, game_versions):
    ids = []
    for interface in interfaces:
        name = interface_to_name(interface)
        matches = [v["id"] for v in game_versions if v["name"] == name]
        if matches:
            ids.extend(matches)
        else:
            print(f"::warning::CurseForge has no game version {name} (interface {interface}); "
                  "uploading without it", file=sys.stderr)
    if not ids:
        sys.exit("none of the TOC's interfaces match a CurseForge game version")
    return ids


def changelog(version, readme):
    # The README's VERSION HISTORY entry for this version, minus its heading.
    match = re.search(rf"^{re.escape(version)}\n(.*?)(?:\n\n|\Z)", readme, re.M | re.S)
    return match.group(1) if match else f"Version {version}"


def release_type(version):
    for kind in ("alpha", "beta"):
        if kind in version:
            return kind
    return "release"


def main():
    with open(TOC) as f:
        toc = f.read()
    with open(README) as f:
        readme = f.read()

    version = re.search(r"^## Version:\s*(\S+)", toc, re.M).group(1)
    interfaces = [int(n) for n in re.search(r"^## Interface:\s*(.+)$", toc, re.M).group(1).split(",")]
    game_versions = fetch_game_versions(os.environ["CF_API_KEY"])

    print(json.dumps({
        "displayName": f"Yeah Right {version}",
        "changelog": changelog(version, readme),
        "changelogType": "text",
        "gameVersions": game_version_ids(interfaces, game_versions),
        "releaseType": release_type(version),
    }))


if __name__ == "__main__":
    main()
