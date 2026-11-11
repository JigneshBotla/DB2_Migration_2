#!/usr/bin/env python3
"""Turn the SnowConvert DB2 output into a deployable Snowflake script.

Reads  snowflake/bigdata_clean.sql   (converter output, left untouched)
       snowflake/procedures_fixed.sql (hand-written procedures)
Writes snowflake/bigdata_deploy.sql

Changes, all mechanical:
  1. Strip !!!RESOLVE EWI!!! /*** ... ***/!!! markers (not valid SQL).
  2. Drop db2look's CONNECT TO <db> statement.
  3. CREATE SCHEMA ... AUTHORIZATION -> CREATE SCHEMA IF NOT EXISTS.
  4. In ALTER TABLE statements, drop DB2-only clauses:
       ENFORCED, ENABLE QUERY OPTIMIZATION, ON DELETE ..., ON UPDATE ...
  5. Collapse "ADD\\n CONSTRAINT" to "ADD CONSTRAINT".
  6. Append ENABLE NOVALIDATE to CHECK constraints (required by Snowflake
     for ALTER TABLE ADD CHECK; still enforced for new writes).
  7. Replace the converted procedures with procedures_fixed.sql.
"""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent
src = root / "snowflake" / "bigdata_clean.sql"
procs = root / "snowflake" / "procedures_fixed.sql"
dest = root / "snowflake" / "bigdata_deploy.sql"

text = src.read_text(encoding="utf-8-sig")
stats = {}

# 1. EWI markers
text, stats["ewi_markers_removed"] = re.subn(
    r"!!!RESOLVE EWI!!!\s*/\*\*\*.*?\*\*\*/!!!", "", text, flags=re.S
)

# split the DDL from the procedures
m = re.search(r"^CREATE PROCEDURE", text, flags=re.M)
if not m:
    sys.exit("could not locate CREATE PROCEDURE boundary")
ddl = text[: m.start()]

# 2. CONNECT TO <db>
ddl, stats["connect_removed"] = re.subn(
    r"^CONNECT TO \w+\s*;\s*$", "", ddl, flags=re.M
)

# 3. CREATE SCHEMA
ddl, stats["schema_rewritten"] = re.subn(
    r'^CREATE SCHEMA\s+("?BIGDATA"?)\s+AUTHORIZATION\s+"?\w+"?\s*;',
    r"CREATE SCHEMA IF NOT EXISTS \1;",
    ddl,
    flags=re.M,
)

# 3b. IDENTITY(+1000, +1) -> IDENTITY(1000, 1).
# SnowConvert carries DB2's signed START WITH / INCREMENT BY through verbatim;
# Snowflake rejects the leading '+'. No EWI is emitted for this.
ddl, stats["identity_signs_fixed"] = re.subn(
    r"IDENTITY\(\s*\+?(-?\d+)\s*,\s*\+?(-?\d+)\s*\)",
    r"IDENTITY(\1, \2)",
    ddl,
)

# 3c. DB2 "ALTER COLUMN <c> RESTART WITH n" has no Snowflake equivalent for an
# existing column. Fold the restart value into that column's IDENTITY start so
# the next generated value matches DB2, then drop the ALTER statement.
restarts = re.findall(
    r'^ALTER TABLE\s+"?\w+\s*"?\.\"?(\w+)"?\s*\n\s*ALTER COLUMN\s+"?(\w+)"?\s+RESTART WITH\s+(\d+)\s*;',
    ddl,
    flags=re.M,
)
for table, column, start in restarts:
    def _fold(match, _s=start):
        return f'{match.group(1)}IDENTITY({_s}, {match.group(2)})'
    ddl = re.sub(
        r'("' + column + r'"[^\n]*?)IDENTITY\(\s*-?\d+\s*,\s*(-?\d+)\s*\)',
        _fold,
        ddl,
    )
ddl, removed_restarts = re.subn(
    r'^ALTER TABLE\s+"?\w+\s*"?\.\"?\w+"?\s*\n\s*ALTER COLUMN\s+"?\w+"?\s+RESTART WITH\s+\d+\s*;\s*$',
    "",
    ddl,
    flags=re.M,
)
stats["identity_restarts_folded"] = removed_restarts

DROP_PATTERNS = (
    re.compile(r"^\s*ENFORCED\s*;?\s*$", re.I),
    re.compile(r"^\s*ENABLE QUERY OPTIMIZATION\s*;?\s*$", re.I),
    re.compile(r"^\s*ON\s+(DELETE|UPDATE)\b.*$", re.I),
)

counters = {"enforced": 0, "enable_query_opt": 0, "referential_actions": 0, "check_novalidate": 0}


def clean_alter(block):
    """Strip DB2-only clauses from one ALTER TABLE statement."""
    is_check = re.search(r"\bCHECK\b", block, re.I) is not None
    kept = []
    for line in block.split("\n"):
        if DROP_PATTERNS[0].match(line):
            counters["enforced"] += 1
            continue
        if DROP_PATTERNS[1].match(line):
            counters["enable_query_opt"] += 1
            continue
        if DROP_PATTERNS[2].match(line):
            counters["referential_actions"] += 1
            continue
        kept.append(line)
    out = "\n".join(kept)
    out = re.sub(r"\bADD\s*\n\s*CONSTRAINT", "ADD CONSTRAINT", out)
    out = out.rstrip().rstrip(";").rstrip()
    if is_check:
        counters["check_novalidate"] += 1
        out += "\n  ENABLE NOVALIDATE;"
    else:
        out += ";"
    return out


# 4-6. walk statements, cleaning only ALTER TABLE ones
lines = ddl.split("\n")
result = []
buf = []
for line in lines:
    buf.append(line)
    if line.rstrip().endswith(";"):
        chunk = "\n".join(buf)
        idx = next(
            (i for i, l in enumerate(buf) if re.match(r"^\s*ALTER TABLE", l, re.I)), None
        )
        if idx is None:
            result.append(chunk)
        else:
            lead = "\n".join(buf[:idx])
            body = clean_alter("\n".join(buf[idx:]))
            result.append((lead + "\n" + body) if lead.strip() else body)
        buf = []
if buf:
    result.append("\n".join(buf))

ddl_out = "\n".join(result)
stats.update(counters)

# 7. procedures
proc_text = procs.read_text(encoding="utf-8")

header = (
    "-- Deployable Snowflake script generated from the SnowConvert DB2 output.\n"
    "-- Source: snowflake/bigdata_clean.sql (unmodified) + snowflake/procedures_fixed.sql\n"
    "-- NOTE: FOREIGN KEY and PRIMARY KEY constraints are metadata only in\n"
    "--       Snowflake and are NOT enforced. CHECK constraints ARE enforced.\n\n"
)

dest.write_text(header + ddl_out.rstrip() + "\n\n" + proc_text, encoding="utf-8")

print("wrote", dest)
for k, v in stats.items():
    print(f"  {k}: {v}")
remaining = len(re.findall(r"RESOLVE EWI|ENFORCED|ENABLE QUERY OPTIMIZATION", dest.read_text()))
print(f"  residual_db2_artifacts: {remaining}")
