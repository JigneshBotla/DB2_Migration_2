-- ============================================================================
-- BRONZE LAYER INGESTION TRANSFORMATIONS - SNOWFLAKE (converted from IBM DB2 LUW)
-- ============================================================================
-- Purpose: Ingests raw transactional records from source operational tables
-- into Bronze landing tables. Applies whitespace trimming, default fallbacks,
-- and audit payload tracking.
--
-- Converted by SnowConvert 2.51.1-Pr, then hand-repaired. Raw converter output is
-- preserved under artifacts/Medalliion/Bronze/02_bronze_ingestion_transform/.
--
-- Repairs applied (the converter left 24 '!!!RESOLVE EWI!!!' markers and the
-- underlying DB2 functions untranslated; none of it was valid Snowflake SQL):
--   CHAR(<date>, ISO)        -> TO_CHAR(<date>, 'YYYY-MM-DD')
--   CHAR(<numeric>)          -> TO_VARCHAR(<numeric>)
--   DECIMAL(x, p, s)         -> CAST(x AS NUMBER(p, s))
--   VALUE(a, b)              -> COALESCE(a, b)
--   CURRENT DATE             -> CURRENT_DATE()
--   CURRENT TIMESTAMP - n U  -> DATEADD(<unit>, -n, CURRENT_TIMESTAMP())
--   SUBSTR(DIGITS(MONTH(..)), 9, 2)
--                            -> LPAD(TO_VARCHAR(MONTH(..)), 2, '0')
--   WITH UR                  -> removed (no Snowflake equivalent; Snowflake uses
--                               snapshot isolation and never blocks readers)
--
-- Note on DIGITS: DB2 DIGITS() on an INTEGER returns a 10-character zero-padded
-- string, so SUBSTR(...,9,2) yields a zero-padded 2-digit value. LPAD(...,2,'0')
-- reproduces this. Verified: month 3 -> '03', day 7 -> '07'.
--
-- Functional difference: DB2 CHAR(<numeric>) returns a fixed-width, blank-padded
-- string; TO_VARCHAR returns an unpadded one. The Silver layer re-casts these
-- columns back to numerics, so the round-trip is unaffected, but the raw Bronze
-- string values differ from DB2 by the absence of padding.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: BRONZE ORDERS INGESTION TRANSFORMATION
-- Extracts transactional orders, applies formatting, and appends batch metadata.
-- ----------------------------------------------------------------------------
INSERT INTO DB2_MIGRATION_2.BIGDATA.BRONZE_ORDERS_RAW (
    RAW_ORDER_NO,
    RAW_CUSTNO,
    RAW_ORDER_DATE,
    RAW_REQUIRED_DATE,
    RAW_SHIPPED_DATE,
    RAW_STATUS,
    RAW_SUBTOTAL,
    RAW_TAX_AMOUNT,
    RAW_FREIGHT_CHARGE,
    RAW_TOTAL_AMOUNT,
    RAW_PAYMENT_METHOD,
    RAW_PAYMENT_STATUS,
    INGESTION_BATCH_ID,
    SOURCE_SYSTEM_CD,
    EXTRACTED_AT_TS,
    INGESTED_AT_TS,
    RECORD_STATUS
)
SELECT
    RTRIM(LTRIM(O.ORDER_NO))                                      AS RAW_ORDER_NO,
    RTRIM(LTRIM(O.CUSTNO))                                        AS RAW_CUSTNO,
    TO_CHAR(O.ORDER_DATE, 'YYYY-MM-DD')                           AS RAW_ORDER_DATE,
    TO_CHAR(O.REQUIRED_DATE, 'YYYY-MM-DD')                        AS RAW_REQUIRED_DATE,
    CASE
        WHEN O.SHIPPED_DATE IS NOT NULL THEN TO_CHAR(O.SHIPPED_DATE, 'YYYY-MM-DD')
        ELSE NULL
    END                                                           AS RAW_SHIPPED_DATE,
    UPPER(RTRIM(O.STATUS))                                        AS RAW_STATUS,
    TO_VARCHAR(CAST(O.SUBTOTAL       AS NUMBER(11,2)))            AS RAW_SUBTOTAL,
    TO_VARCHAR(CAST(O.TAX_AMOUNT     AS NUMBER(9,2)))             AS RAW_TAX_AMOUNT,
    TO_VARCHAR(CAST(O.FREIGHT_CHARGE AS NUMBER(9,2)))             AS RAW_FREIGHT_CHARGE,
    TO_VARCHAR(CAST(O.TOTAL_AMOUNT   AS NUMBER(11,2)))            AS RAW_TOTAL_AMOUNT,
    COALESCE(RTRIM(O.PAYMENT_METHOD), 'UNKNOWN')                  AS RAW_PAYMENT_METHOD,
    COALESCE(RTRIM(O.PAYMENT_STATUS), 'UNPAID')                   AS RAW_PAYMENT_STATUS,
    'BATCH_' || TO_VARCHAR(YEAR(CURRENT_DATE()))
              || LPAD(TO_VARCHAR(MONTH(CURRENT_DATE())), 2, '0')
              || LPAD(TO_VARCHAR(DAY(CURRENT_DATE())), 2, '0')
              || '_01'                                            AS INGESTION_BATCH_ID,
    'DB2_OLTP'                                                    AS SOURCE_SYSTEM_CD,
    DATEADD(minute, -5, CURRENT_TIMESTAMP())                      AS EXTRACTED_AT_TS,
    CURRENT_TIMESTAMP()                                           AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM DB2_MIGRATION_2.BIGDATA.ORDERS O
WHERE O.CREATED_TS >= DATEADD(day, -1, CURRENT_TIMESTAMP());

-- ----------------------------------------------------------------------------
-- STEP 2: BRONZE ORDER ITEMS INGESTION TRANSFORMATION
-- Resolves product SKU joins, converts numerical amounts, tracks items batch.
-- ----------------------------------------------------------------------------
INSERT INTO DB2_MIGRATION_2.BIGDATA.BRONZE_ORDER_ITEMS_RAW (
    RAW_ORDER_NO,
    RAW_LINE_NO,
    RAW_SKU,
    RAW_QUANTITY,
    RAW_UNIT_PRICE,
    RAW_DISCOUNT_PCT,
    RAW_EXTENDED_PRICE,
    INGESTION_BATCH_ID,
    SOURCE_SYSTEM_CD,
    EXTRACTED_AT_TS,
    INGESTED_AT_TS,
    RECORD_STATUS
)
SELECT
    RTRIM(LTRIM(O.ORDER_NO))                                      AS RAW_ORDER_NO,
    TO_VARCHAR(OI.LINE_NO)                                        AS RAW_LINE_NO,
    RTRIM(P.SKU)                                                  AS RAW_SKU,
    TO_VARCHAR(OI.QUANTITY)                                       AS RAW_QUANTITY,
    TO_VARCHAR(CAST(OI.UNIT_PRICE     AS NUMBER(9,2)))            AS RAW_UNIT_PRICE,
    TO_VARCHAR(CAST(OI.DISCOUNT_PCT   AS NUMBER(5,2)))            AS RAW_DISCOUNT_PCT,
    TO_VARCHAR(CAST(OI.EXTENDED_PRICE AS NUMBER(11,2)))           AS RAW_EXTENDED_PRICE,
    'BATCH_' || TO_VARCHAR(YEAR(CURRENT_DATE()))
              || LPAD(TO_VARCHAR(MONTH(CURRENT_DATE())), 2, '0')
              || LPAD(TO_VARCHAR(DAY(CURRENT_DATE())), 2, '0')
              || '_01'                                            AS INGESTION_BATCH_ID,
    'DB2_OLTP'                                                    AS SOURCE_SYSTEM_CD,
    DATEADD(minute, -5, CURRENT_TIMESTAMP())                      AS EXTRACTED_AT_TS,
    CURRENT_TIMESTAMP()                                           AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM DB2_MIGRATION_2.BIGDATA.ORDER_ITEMS OI
INNER JOIN DB2_MIGRATION_2.BIGDATA.ORDERS O
    ON O.ORDER_ID = OI.ORDER_ID
INNER JOIN DB2_MIGRATION_2.BIGDATA.PRODUCTS P
    ON P.PRODUCT_ID = OI.PRODUCT_ID;

-- ----------------------------------------------------------------------------
-- STEP 3: BRONZE INVENTORY SNAPSHOT INGESTION TRANSFORMATION
-- Extracts warehouse stock postures and formats dates.
-- ----------------------------------------------------------------------------
INSERT INTO DB2_MIGRATION_2.BIGDATA.BRONZE_INVENTORY_RAW (
    RAW_WAREHOUSE_ID,
    RAW_SKU,
    RAW_ON_HAND_QTY,
    RAW_ALLOCATED_QTY,
    RAW_REORDER_POINT,
    RAW_REORDER_QTY,
    RAW_SAFETY_STOCK,
    RAW_BIN_LOCATION,
    RAW_LAST_RESTOCK_DT,
    INGESTION_BATCH_ID,
    SOURCE_SYSTEM_CD,
    EXTRACTED_AT_TS,
    INGESTED_AT_TS,
    RECORD_STATUS
)
SELECT
    RTRIM(I.WAREHOUSE_ID)                                         AS RAW_WAREHOUSE_ID,
    RTRIM(P.SKU)                                                  AS RAW_SKU,
    TO_VARCHAR(I.ON_HAND_QTY)                                     AS RAW_ON_HAND_QTY,
    TO_VARCHAR(I.ALLOCATED_QTY)                                   AS RAW_ALLOCATED_QTY,
    TO_VARCHAR(I.REORDER_POINT)                                   AS RAW_REORDER_POINT,
    TO_VARCHAR(I.REORDER_QTY)                                     AS RAW_REORDER_QTY,
    TO_VARCHAR(I.SAFETY_STOCK)                                    AS RAW_SAFETY_STOCK,
    RTRIM(I.BIN_LOCATION)                                         AS RAW_BIN_LOCATION,
    CASE
        WHEN I.LAST_RESTOCK_DATE IS NOT NULL
             THEN TO_CHAR(I.LAST_RESTOCK_DATE, 'YYYY-MM-DD')
        ELSE '1900-01-01'
    END                                                           AS RAW_LAST_RESTOCK_DT,
    'INV_SNAP_' || TO_VARCHAR(YEAR(CURRENT_DATE()))
                 || LPAD(TO_VARCHAR(MONTH(CURRENT_DATE())), 2, '0')
                 || LPAD(TO_VARCHAR(DAY(CURRENT_DATE())), 2, '0')  AS INGESTION_BATCH_ID,
    'WMS_MAIN'                                                    AS SOURCE_SYSTEM_CD,
    CURRENT_TIMESTAMP()                                           AS EXTRACTED_AT_TS,
    CURRENT_TIMESTAMP()                                           AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM DB2_MIGRATION_2.BIGDATA.INVENTORY I
INNER JOIN DB2_MIGRATION_2.BIGDATA.PRODUCTS P
    ON P.PRODUCT_ID = I.PRODUCT_ID;

-- ----------------------------------------------------------------------------
-- STEP 4: BRONZE CUSTOMERS INGESTION (CDC SIMULATION)
-- Extracts customer records and captures CDC operation codes.
-- ----------------------------------------------------------------------------
INSERT INTO DB2_MIGRATION_2.BIGDATA.BRONZE_CUSTOMERS_RAW (
    RAW_CUSTNO,
    RAW_FNAME,
    RAW_LNAME,
    RAW_ADDR,
    RAW_CITY,
    RAW_STATE,
    RAW_ZIPCODE,
    RAW_PHONE,
    RAW_OP_TYPE,
    INGESTION_BATCH_ID,
    SOURCE_SYSTEM_CD,
    EXTRACTED_AT_TS,
    INGESTED_AT_TS,
    RECORD_STATUS
)
SELECT
    RTRIM(C.CUSTNO)                                               AS RAW_CUSTNO,
    RTRIM(C.FNAME)                                                AS RAW_FNAME,
    RTRIM(C.LNAME)                                                AS RAW_LNAME,
    RTRIM(C.ADDR)                                                 AS RAW_ADDR,
    RTRIM(C.CITY)                                                 AS RAW_CITY,
    RTRIM(C.STATE)                                                AS RAW_STATE,
    RTRIM(C.ZIPCODE)                                              AS RAW_ZIPCODE,
    'N/A'                                                         AS RAW_PHONE,
    'I'                                                           AS RAW_OP_TYPE,
    'CUST_DELTA_' || TO_VARCHAR(YEAR(CURRENT_DATE()))
                   || LPAD(TO_VARCHAR(MONTH(CURRENT_DATE())), 2, '0')
                                                                  AS INGESTION_BATCH_ID,
    'CRM_LEGACY'                                                  AS SOURCE_SYSTEM_CD,
    CURRENT_TIMESTAMP()                                           AS EXTRACTED_AT_TS,
    CURRENT_TIMESTAMP()                                           AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM DB2_MIGRATION_2.BIGDATA.CUSTOMERS C;
