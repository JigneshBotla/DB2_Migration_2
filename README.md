# DB2 → Snowflake Migration: `BIGDATA` schema

Migration of the `BIGDATA` schema from IBM DB2 to Snowflake using Snowflake AIM
for Data Warehouses (SnowConvert 2.51.1-Pr), plus manual repair of the converted
code.

**Status: converted, repaired, deployed and functionally verified. No data has
been migrated.**

## Source and target

| | |
|---|---|
| Source | IBM DB2 12.1.5.0, Docker container `mydb2`, database `testdb`, schema `BIGDATA` |
| Target | Snowflake `DB2_MIGRATION_SCRATCH.BIGDATA` (account `QAQGBZD-SNOWCONVERT_AI_POC`, connection `db2_aim_key`, warehouse `MIGRATION_WH`) |

30 objects: 1 schema, 2 sequences, 11 tables, 8 views, 3 functions, 6 procedures.
No triggers; all routines are `LANGUAGE SQL`. Constraints: 11 primary keys,
11 check constraints, 9 foreign keys. `SALES_DEMO` was out of scope.

`DB2_MIGRATION_SCRATCH` began as a verification sandbox and was retained as the
target by decision. It is not a production target.

## DB2 is a conversion-only source in AIM

The full lifecycle is supported only for SqlServer, Redshift, Teradata,
Postgresql, Oracle, BigQuery and AzureSynapse. For DB2, each of these was tried
and failed:

| Capability | Result |
|---|---|
| `scai code extract` | `EXT0003: Code extraction is not supported for this source language` |
| `scai code deploy` | `DEP0008: Code deployment is not supported for source language 'Db2'` |
| Code Unit Registry | Never generated (no arrange phase for DB2) |
| `scai assessment waves` / `object-exclusion` / `data-lineage` | `ASM0011` / `ASM0026` / `ASM0035` — all need the registry |
| `query_source` ad-hoc SQL | `QRY0006` — connection test only |

So there is **no per-object tracking, no dependency waves and no assessment
report**. DDL came from `db2look` inside the container, and deployment was
manual via `snow sql`.

## Files

| Path | Description |
|---|---|
| `db2_ddl/bigdata.sql` | Pristine `db2look` output. Never edited. |
| `db2_ddl/bigdata_clean.sql` | Same, minus `db2look` session scaffolding. |
| `source/bigdata_clean.sql` | Conversion input as registered. |
| `snowflake/bigdata_clean.sql` | Raw SnowConvert output. **Not deployable.** |
| `snowflake/bigdata_deploy.sql` | **The deployable script.** Verified. |
| `snowflake/procedures_fixed.sql` | The 6 procedures, hand-rewritten. |
| `snowflake/cascade_procedures.sql` | `SP_DELETE_INVOICE`, `SP_DELETE_ORDER` — new. |
| `make_deployable.py` | Re-runnable transform producing `bigdata_deploy.sql`. |
| `.scai/reports/SnowConvert/` | Conversion reports, incl. `Issues.*.csv`. |

### Redeploy

```bash
python3 make_deployable.py
{ echo "USE WAREHOUSE MIGRATION_WH;"; echo "USE DATABASE DB2_MIGRATION_SCRATCH;"; \
  cat snowflake/bigdata_deploy.sql; } | snow sql -c db2_aim_key -i
{ echo "USE SCHEMA DB2_MIGRATION_SCRATCH.BIGDATA;"; \
  cat snowflake/cascade_procedures.sql; } | snow sql -c db2_aim_key -i
```

Tables use bare `CREATE`, so re-running against a populated schema fails with
`42710`. Drop the schema first for a clean redeploy.

## Defects found in the converted output

SnowConvert's JSON envelope reported `76 issues`, severities `{medium: 1,
low: 2}`, **no critical count**. The `Issues` CSV for the same run had **132
rows, 56 Critical**. The envelope excludes parse errors — do not use it to judge
correctness.

| # | Defect | Warned? | Fix |
|---|---|---|---|
| 1 | 56 parse errors from `db2look`'s repeated `SET SYSIBM.NLS_STRING_UNITS` / `SET CURRENT SCHEMA` / `SET CURRENT PATH` | Critical | 54 lines filtered from input |
| 2 | `!!!RESOLVE EWI!!!` markers are **not valid SQL** | No | 50 stripped |
| 3 | `IN`/`OUT` parameter modes emitted; Snowflake has none | Only "Medium" | Procedures rewritten |
| 4 | `GET DIAGNOSTICS … ROW_COUNT` | Medium | `V_ROWS := SQLROWCOUNT` |
| 5 | `CONDITION FOR SQLSTATE` + `SIGNAL` | Medium | `DECLARE … EXCEPTION` + `RAISE` |
| 6 | `DAYS()` / `DIGITS()` — neither exists in Snowflake | Medium | `DATEDIFF`; `RIGHT(LPAD(TO_VARCHAR(ABS(x)),10,'0'),6)` |
| 7 | `IDENTITY(+1000, +1)` — `+` rejected | **None** | 6 de-signed |
| 8 | `ALTER COLUMN … RESTART WITH 6000` | Medium | Folded into `IDENTITY` start |
| 9 | `ENFORCED` (35), `ENABLE QUERY OPTIMIZATION` (11) | Partly (FDM) | Removed |
| 10 | `SSC-EWI-0035 "CHECK STATEMENT NOT SUPPORTED"` | — | **The EWI is wrong** (below) |
| 11 | `EXIT HANDLER FOR NOT FOUND` remapped to `42S02` | **None — silent logic bug** | Intent restored |

### Defect 10: `CHECK` constraints are supported and enforced

Verified: inserting `DISCOUNT_PCT = 250` into `PROMOTIONS` is rejected. All 11
check constraints were preserved. `ALTER TABLE … ADD CONSTRAINT … CHECK`
requires `ENABLE NOVALIDATE`, which skips validating existing rows but still
enforces new writes.

### Defect 11: the silent handler bug

DB2 used `EXIT HANDLER FOR NOT FOUND` (SQLSTATE `02000`, "no rows"). SnowConvert
emitted `WHEN OTHER EXIT THEN CASE WHEN SQLSTATE = '42S02'` — "table not found",
a different condition. The handler would fire only if `CUSTOMERS` were missing
and **never** when a customer did not exist. `SP_PLACE_ORDER` would silently
have accepted orders for non-existent customers.

Same class: `SP_CHECK_INVENTORY_SHORTAGE` used `CONTINUE HANDLER FOR NOT FOUND
SET V_AT_END = 1` for cursor exhaustion, remapped to `42S02`, so `V_AT_END`
never became 1 — **an infinite `WHILE` loop**. Both now use cursor `FOR` loops.

## Procedure interface changes

Snowflake procedures take input-only parameters and return one value, so every
`OUT` parameter became part of the return. **Breaking change for callers.**

| Procedure | DB2 `OUT` | Snowflake |
|---|---|---|
| `SP_ADD_CUSTOMER` | `P_STATUS` | `RETURNS INTEGER` |
| `SP_REFRESH_CUSTOMER_SUMMARY` | `P_ROWS` | `RETURNS INTEGER` |
| `SP_UPDATE_CUSTOMER_ADDRESS` | `P_ROWS` | `RETURNS INTEGER` |
| `SP_RESTOCK_INVENTORY` | `P_NEW_ON_HAND` | `RETURNS INTEGER` |
| `SP_CHECK_INVENTORY_SHORTAGE` | count + deficit | `RETURNS OBJECT` |
| `SP_PLACE_ORDER` | order id + total | `RETURNS OBJECT` |

Deliberate behaviour change: `SP_ADD_CUSTOMER` handled `SQLSTATE 23505` to
return `-1`, but Snowflake does not enforce primary keys so that could never
fire. The duplicate check is now an explicit `COUNT(*)` probe.

## Constraint semantics (each verified by execution)

| Constraint | Count | Declared | Enforced |
|---|---|---|---|
| `CHECK` | 11 | Yes | **Yes** |
| `PRIMARY KEY` | 11 | Metadata | **No** |
| `FOREIGN KEY` | 9 | Metadata | **No** |

### Lost `ON DELETE CASCADE` — mitigated

`LINES_INV_FK` (`INVOICE_LINES`→`INVOICES`) and `ITEMS_ORDER_FK`
(`ORDER_ITEMS`→`ORDERS`) were `ON DELETE CASCADE`. Snowflake ignores this, so a
parent delete orphans children with no error. Replaced by
`SP_DELETE_INVOICE(invno)` and `SP_DELETE_ORDER(order_id)`, which delete children
then parent in one transaction and roll back on error.

> These only help if callers use them. A plain `DELETE FROM INVOICES` still
> orphans children silently.

### Unenforced orphan prevention — risk accepted

| Constraint | Relationship | Covered? |
|---|---|---|
| `ORDERS_CUST_FK` | `ORDERS.CUSTNO` → `CUSTOMERS` | Yes — `SP_PLACE_ORDER` checks |
| `TXN_PROD_FK` | `INVENTORY_TRANSACTIONS.PRODUCT_ID` → `PRODUCTS` | Partly |
| `INV_CUST_FK` | `INVOICES.INVCUST` → `CUSTOMERS` | No |
| `INV_PROM_FK` | `INVOICES.INVPROM` → `PROMOTIONS` | No |
| `LINES_PROD_FK` | `INVOICE_LINES.PRODUCT_ID` → `PRODUCTS` | No |
| `ITEMS_PROD_FK` | `ORDER_ITEMS.PRODUCT_ID` → `PRODUCTS` | No |
| `INV_PROD_FK` | `INVENTORY.PRODUCT_ID` → `PRODUCTS` | No |

`INVOICES`, `INVOICE_LINES`, `ORDER_ITEMS`, `PRODUCTS` and `PROMOTIONS` are not
written by any procedure, so enforcement must live in whatever loads them.

## Verification

Deployed with zero errors: 1 schema, 2 sequences, 11 tables, 8 views,
3 functions, 8 procedures (6 migrated + 2 new).

| Test | Result |
|---|---|
| `FN_FORMAT_INVNO(62358)` / `(1234567)` | `062358` / `234567` — match DB2 |
| `FN_INVOICE_TOTAL(100,15,6)` | `121.00` |
| `FN_CUSTOMER_FULLNAME('Ada  ','Lovelace ')` | `Ada Lovelace` |
| `SP_CHECK_INVENTORY_SHORTAGE()` | `{0, 0}` — returns, does not hang |
| `SP_ADD_CUSTOMER` new / duplicate | `0` then `-1` |
| `SP_UPDATE_CUSTOMER_ADDRESS` | `1` |
| `SP_PLACE_ORDER` | `{order_id: 5000, total_amount: 227}` = 200 + 12 TX tax + 15 freight |
| `SP_PLACE_ORDER` unknown customer | raises `CUST_MISSING` |
| `SP_RESTOCK_INVENTORY` unknown item | raises `INV_NOT_FOUND` |
| `PROMOTIONS.DISCOUNT_PCT = 250` | rejected |
| `SP_DELETE_INVOICE` / `SP_DELETE_ORDER` | children + parent removed, counts correct |

`FN_FORMAT_INVNO` was checked against DB2's own output for `62358`, `1234567`,
`5`, `-42`, `0`. A first attempt with `LPAD(…, 6, '0')` gave `123456` where DB2
gives `234567` — Snowflake's `LPAD` **truncates** when the target length is
shorter than the input. DB2's `DIGITS` pads an `INTEGER` to 10 chars, so the
correct form pads to 10 then takes the right 6.

All test rows were removed; every table is empty.

## Open items

1. **No data migrated.** Must be done manually (`db2 export` → `PUT` →
   `COPY INTO`) with per-table row-count and checksum verification.
2. **7 foreign keys unenforced**, risk accepted.
3. **Cascade deletes depend on callers** using the two new procedures.
4. **`OUT` → return value breaks every existing caller** of the 6 procedures.
5. **No table-to-table lineage.** Snowflake lineage is built from data movement,
   not relationships, and foreign keys never appear in it. The tables are empty,
   and `SP_REFRESH_CUSTOMER_SUMMARY` writes row-by-row from a cursor
   (`INSERT … VALUES (R.col, …)`), so values cannot be attributed back to
   `INVOICES`. A set-based `INSERT … SELECT` would be faster and would produce
   the lineage edge; the cursor form was kept as a faithful translation.
6. **No assessment report** — unavailable for DB2.
