#!/usr/bin/env python3
"""Merge pinned CLDR 48 English annotations into the offline emoji catalog.

Download common/annotations/en.xml and common/annotationsDerived/en.xml from
https://github.com/unicode-org/cldr/tree/release-48 and pass both local paths.
Existing aliases and hand-tuned keywords are preserved. Unicode-3.0 licensed;
see Ogma/Resources/UNICODE_LICENSE.txt.
"""

import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("annotations", nargs=2, type=Path)
    args = parser.parse_args()
    annotations = {}
    for path in args.annotations:
        for annotation in ET.parse(path).findall(".//annotation"):
            if annotation.get("type") == "tts" or not annotation.text:
                continue
            key = annotation.attrib["cp"].replace("\ufe0f", "")
            annotations.setdefault(key, set()).update(
                term.strip().lower() for term in annotation.text.split("|")
            )

    catalog = Path(__file__).resolve().parents[1] / "Ogma/Resources/emoji.json"
    items = json.loads(catalog.read_text())
    covered = 0
    for item in items:
        terms = annotations.get(item["emoji"].replace("\ufe0f", ""), set())
        covered += bool(terms)
        existing = item["keywords"]
        item["keywords"] = existing + sorted(terms - set(existing))
    catalog.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n")
    print(f"CLDR keywords merged for {covered}/{len(items)} emoji")


if __name__ == "__main__":
    main()
