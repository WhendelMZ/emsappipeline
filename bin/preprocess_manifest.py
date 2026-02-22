#!/usr/bin/env python3
"""
Manifest FASTA checker + merger

Input CSV columns:
  id,fasta_file_path,label

Outputs:
  1) results CSV with sequence length + non-standard symbol info
  2) merged multi-sequence FASTA with headers: >{id}

Assumes each FASTA file contains a single sequence record (may be multiline).
"""

import csv
import sys
from typing import Dict, List, Set, Tuple


STANDARD_AA: Set[str] = set("ACDEFGHIKLMNPQRSTVWY")


def read_single_fasta_sequence(path: str) -> str:
    """
    Read a FASTA file and return the concatenated sequence.
    Ignores header lines (starting with '>').
    Removes all whitespace from sequence lines.
    """
    seq_chunks: List[str] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if not line:
                continue
            if line.startswith(">"):
                continue
            seq_chunks.append("".join(line.split()))  # remove all whitespace
    return "".join(seq_chunks)


def check_nonstandard_symbols(
    seq: str,
    *,
    allow_ambiguous: bool = True,
    allow_stop: bool = True,
    allow_gap: bool = True,
    allow_lowercase: bool = True,
) -> Tuple[bool, List[str], int]:
    """
    Returns:
      has_nonstandard (bool),
      nonstandard_symbols (sorted list),
      nonstandard_count (total occurrences)
    """
    allowed: Set[str] = set(STANDARD_AA)

    if allow_ambiguous:
        allowed.update(set("BJZX"))  # IUPAC ambiguous/unknown
    if allow_stop:
        allowed.add("*")
    if allow_gap:
        allowed.update(set("-."))
    # whitespace removed earlier

    seq_to_check = seq.upper() if allow_lowercase else seq

    nonstd_set: Set[str] = set()
    nonstd_count = 0

    for ch in seq_to_check:
        if ch not in allowed:
            nonstd_set.add(ch)
            nonstd_count += 1

    return (nonstd_count > 0), sorted(nonstd_set), nonstd_count


def get_manifest_entries(manifest_csv: str) -> List[Dict[str, str]]:
    """
    Read manifest CSV and return a list of entries with keys:
      id, fasta_file_path, label
    """
    entries: List[Dict[str, str]] = []
    with open(manifest_csv, "r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            entries.append(
                {
                    "id": (row.get("id") or "").strip(),
                    "fasta_file_path": (row.get("fasta_file_path") or "").strip(),
                    "label": (row.get("label") or "").strip(),
                }
            )
    return entries


def write_multiseq_fasta_from_manifest(
    entries: List[Dict[str, str]],
    output_fasta: str,
    *,
    wrap: int = 60,
) -> None:
    """
    Create a multi-sequence FASTA file from manifest entries.
    Each record header is exactly: >{id}
    Sequences are wrapped to `wrap` characters per line (FASTA-friendly).
    """
    with open(output_fasta, "w", encoding="utf-8") as out:
        for ent in entries:
            rec_id = ent["id"]
            path = ent["fasta_file_path"]

            seq = read_single_fasta_sequence(path)

            out.write(f">{rec_id}\n")
            if wrap and wrap > 0:
                for i in range(0, len(seq), wrap):
                    out.write(seq[i : i + wrap] + "\n")
            else:
                out.write(seq + "\n")


def main(argv: List[str]) -> int:
    if len(argv) < 4:
        print(
            f"Usage: {argv[0]} manifest.csv results.csv merged.fasta\n"
            f"Example: {argv[0]} manifest.csv qc_results.csv all_sequences.fasta",
            file=sys.stderr,
        )
        return 2

    manifest_csv = argv[1]
    results_csv = argv[2]
    merged_fasta = argv[3]

    # Customize these defaults if you want stricter checking:
    allow_ambiguous = True  # B, Z, J, X allowed
    allow_stop = True       # * allowed
    allow_gap = True        # - and . allowed

    entries = get_manifest_entries(manifest_csv)

    # 1) Write merged multi-sequence FASTA
    write_multiseq_fasta_from_manifest(entries, merged_fasta, wrap=60)

    # 2) Write results CSV
    fieldnames = [
        "id",
        "fasta_file_path",
        "label",
        "sequence_length",
        "has_nonstandard_symbols",
        "nonstandard_symbols",
        "nonstandard_count",
        "error",
    ]

    with open(results_csv, "w", newline="", encoding="utf-8") as out:
        writer = csv.DictWriter(out, fieldnames=fieldnames)
        writer.writeheader()

        for ent in entries:
            rec_id = ent["id"]
            fasta_path = ent["fasta_file_path"]
            label = ent["label"]

            out_row: Dict[str, str] = {
                "id": rec_id,
                "fasta_file_path": fasta_path,
                "label": label,
                "sequence_length": "",
                "has_nonstandard_symbols": "",
                "nonstandard_symbols": "",
                "nonstandard_count": "",
                "error": "",
            }

            try:
                seq = read_single_fasta_sequence(fasta_path)
                seq_len = len(seq)

                has_nonstd, nonstd_syms, nonstd_count = check_nonstandard_symbols(
                    seq,
                    allow_ambiguous=allow_ambiguous,
                    allow_stop=allow_stop,
                    allow_gap=allow_gap,
                    allow_lowercase=True,
                )

                out_row["sequence_length"] = str(seq_len)
                out_row["has_nonstandard_symbols"] = "1" if has_nonstd else "0"
                out_row["nonstandard_symbols"] = "".join(nonstd_syms)  # e.g. "OU"
                out_row["nonstandard_count"] = str(nonstd_count)

            except Exception as e:
                out_row["error"] = f"{type(e).__name__}: {e}"

            writer.writerow(out_row)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))