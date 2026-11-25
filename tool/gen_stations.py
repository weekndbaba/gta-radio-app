"""Builds assets/stations.json + pubspec asset list from files in assets/audio/.
If no audio files are found, leaves the default (online demo) stations.json alone."""
import json, os, re

ROOT = "assets/audio"
EXT = {".mp3", ".m4a", ".aac", ".ogg", ".opus", ".wav", ".flac"}
PALETTE = ["#2a6f97", "#6d597a", "#355070", "#b56576", "#588157", "#bc6c25", "#7b2cbf", "#0077b6"]
GROUP_COLORS = ["#ea2a33", "#1d7874", "#7b2cbf", "#e07a1f", "#2a6f97", "#b5179e"]

def pretty(n):
    return re.sub(r"[_\-]+", " ", os.path.splitext(n)[0]).strip()

groups, dirs = {}, set()
for dp, _, files in os.walk(ROOT):
    for f in sorted(files):
        if os.path.splitext(f)[1].lower() not in EXT:
            continue
        if " " in f or " " in dp:
            print("WARNING: avoid spaces in file/folder names:", os.path.join(dp, f))
        rel = os.path.relpath(dp, ROOT)
        gname = "My Stations" if rel == "." else pretty(rel.split(os.sep)[0])
        groups.setdefault(gname, []).append(os.path.join(dp, f).replace(os.sep, "/"))
        dirs.add(dp.replace(os.sep, "/") + "/")

if not groups:
    print("no audio found; keeping default stations.json")
    raise SystemExit(0)

out = {"groups": []}
for gi, (gname, paths) in enumerate(sorted(groups.items())):
    out["groups"].append({
        "name": gname,
        "color": GROUP_COLORS[gi % len(GROUP_COLORS)],
        "stations": [
            {"name": pretty(os.path.basename(p)), "url": p, "sync_loop": True,
             "color": PALETTE[i % len(PALETTE)]}
            for i, p in enumerate(sorted(paths))
        ],
    })
json.dump(out, open("assets/stations.json", "w"), indent=2)

pub = open("pubspec.yaml").read()
head = pub.split("  assets:")[0]
assets = "  assets:\n    - assets/stations.json\n" + "".join(f"    - {d}\n" for d in sorted(dirs))
open("pubspec.yaml", "w").write(head + assets)
print("generated", sum(len(v) for v in groups.values()), "stations in", len(groups), "groups")
