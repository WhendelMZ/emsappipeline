#!/usr/bin/env python3
import argparse
import re
import requests

VALID_AA_RE = re.compile(r"^[ACDEFGHIKLMNPQRSTVWYBJZX\*\-\.]+$", re.I)

def validate_sequence(seq: str) -> str:
    seq = "".join(seq.split()).upper()
    if not seq:
        raise ValueError("Sequence is empty.")
    if not VALID_AA_RE.match(seq):
        bad = sorted(set(re.sub(r"[ACDEFGHIKLMNPQRSTVWYBJZX\*\-\.]", "", seq)))
        raise ValueError(f"Invalid amino-acid symbols found: {bad}")
    return seq

def main() -> int:
    ap = argparse.ArgumentParser(description="Run ESMFold via ESM Atlas API")
    ap.add_argument("--seq", required=True, help="Protein sequence")
    ap.add_argument("-o", "--out", required=True, help="Output PDB file")
    args = ap.parse_args()

    sequence = validate_sequence(args.seq)

    resp = requests.post(
        "https://api.esmatlas.com/foldSequence/v1/pdb/",
        data=sequence,
        timeout=600,
    )
    resp.raise_for_status()

    with open(args.out, "w", encoding="utf-8") as f:
        f.write(resp.text)

    print(f"PDB saved to: {args.out}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())