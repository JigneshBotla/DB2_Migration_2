-- ============================================================================
-- BRONZE LAYER INGESTION TRANSFORMATIONS - IBM DB2 LUW LEGACY DIALECT
-- ============================================================================
-- Purpose: Ingests raw transactional records from source operational tables
-- into Bronze landing tables. Implements data type formatting, whitespace
-- trimming (RTRIM/LTRIM), default fallback assignments (VALUE/COALESCE),
-- audit payload tracking, and isolation clause (WITH UR).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: BRONZE ORDERS INGESTION TRANSFORMATION
-- Extracts transactional orders, applies legacy formatting, and appends batch metadata.
-- ----------------------------------------------------------------------------
INSERT INTO BRONZE_ORDERS_RAW (
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
    CHAR(O.ORDER_DATE, ISO)                                       AS RAW_ORDER_DATE,
    CHAR(O.REQUIRED_DATE, ISO)                                    AS RAW_REQUIRED_DATE,
    CASE 
        WHEN O.SHIPPED_DATE IS NOT NULL THEN CHAR(O.SHIPPED_DATE, ISO)
        ELSE NULL 
    END                                                           AS RAW_SHIPPED_DATE,
    UPPER(RTRIM(O.STATUS))                                        AS RAW_STATUS,
    CHAR(DECIMAL(O.SUBTOTAL, 11, 2))                              AS RAW_SUBTOTAL,
    CHAR(DECIMAL(O.TAX_AMOUNT, 9, 2))                             AS RAW_TAX_AMOUNT,
    CHAR(DECIMAL(O.FREIGHT_CHARGE, 9, 2))                         AS RAW_FREIGHT_CHARGE,
    CHAR(DECIMAL(O.TOTAL_AMOUNT, 11, 2))                          AS RAW_TOTAL_AMOUNT,
    VALUE(RTRIM(O.PAYMENT_METHOD), 'UNKNOWN')                     AS RAW_PAYMENT_METHOD,
    VALUE(RTRIM(O.PAYMENT_STATUS), 'UNPAID')                      AS RAW_PAYMENT_STATUS,
    'BATCH_' || CHAR(YEAR(CURRENT DATE)) || 
    SUBSTR(DIGITS(MONTH(CURRENT DATE)), 9, 2) || 
    SUBSTR(DIGITS(DAY(CURRENT DATE)), 9, 2) || '_01'             AS INGESTION_BATCH_ID,
    'DB2_OLTP'                                                    AS SOURCE_SYSTEM_CD,
    CURRENT TIMESTAMP - 5 MINUTES                                 AS EXTRACTED_AT_TS,
    CURRENT TIMESTAMP                                             AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM ORDERS O
WHERE O.CREATED_TS >= (CURRENT TIMESTAMP - 1 DAY)
WITH UR;

-- ----------------------------------------------------------------------------
-- STEP 2: BRONZE ORDER ITEMS INGESTION TRANSFORMATION
-- Resolves product SKU joins, converts numerical amounts, tracks items batch.
-- ----------------------------------------------------------------------------
INSERT INTO BRONZE_ORDER_ITEMS_RAW (
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
    CHAR(OI.LINE_NO)                                              AS RAW_LINE_NO,
    RTRIM(P.SKU)                                                  AS RAW_SKU,
    CHAR(OI.QUANTITY)                                             AS RAW_QUANTITY,
    CHAR(DECIMAL(OI.UNIT_PRICE, 9, 2))                            AS RAW_UNIT_PRICE,
    CHAR(DECIMAL(OI.DISCOUNT_PCT, 5, 2))                          AS RAW_DISCOUNT_PCT,
    CHAR(DECIMAL(OI.EXTENDED_PRICE, 11, 2))                       AS RAW_EXTENDED_PRICE,
    'BATCH_' || CHAR(YEAR(CURRENT DATE)) || 
    SUBSTR(DIGITS(MONTH(CURRENT DATE)), 9, 2) || 
    SUBSTR(DIGITS(DAY(CURRENT DATE)), 9, 2) || '_01'             AS INGESTION_BATCH_ID,
    'DB2_OLTP'                                                    AS SOURCE_SYSTEM_CD,
    CURRENT TIMESTAMP - 5 MINUTES                                 AS EXTRACTED_AT_TS,
    CURRENT TIMESTAMP                                             AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM ORDER_ITEMS OI
INNER JOIN ORDERS O ON O.ORDER_ID = OI.ORDER_ID
INNER JOIN PRODUCTS P ON P.PRODUCT_ID = OI.PRODUCT_ID
WITH UR;

-- ----------------------------------------------------------------------------
-- STEP 3: BRONZE INVENTORY SNAPSHOT INGESTION TRANSFORMATION
-- Extracts warehouse stock postures, formats dates using legacy DB2 functions.
-- ----------------------------------------------------------------------------
INSERT INTO BRONZE_INVENTORY_RAW (
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
    CHAR(I.ON_HAND_QTY)                                           AS RAW_ON_HAND_QTY,
    CHAR(I.ALLOCATED_QTY)                                         AS RAW_ALLOCATED_QTY,
    CHAR(I.REORDER_POINT)                                         AS RAW_REORDER_POINT,
    CHAR(I.REORDER_QTY)                                           AS RAW_REORDER_QTY,
    CHAR(I.SAFETY_STOCK)                                          AS RAW_SAFETY_STOCK,
    RTRIM(I.BIN_LOCATION)                                         AS RAW_BIN_LOCATION,
    CASE 
        WHEN I.LAST_RESTOCK_DATE IS NOT NULL THEN CHAR(I.LAST_RESTOCK_DATE, ISO)
        ELSE '1900-01-01'
    END                                                           AS RAW_LAST_RESTOCK_DT,
    'INV_SNAP_' || CHAR(YEAR(CURRENT DATE)) || 
    SUBSTR(DIGITS(MONTH(CURRENT DATE)), 9, 2) || 
    SUBSTR(DIGITS(DAY(CURRENT DATE)), 9, 2)                      AS INGESTION_BATCH_ID,
    'WMS_MAIN'                                                    AS SOURCE_SYSTEM_CD,
    CURRENT TIMESTAMP                                             AS EXTRACTED_AT_TS,
    CURRENT TIMESTAMP                                             AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM INVENTORY I
INNER JOIN PRODUCTS P ON P.PRODUCT_ID = I.PRODUCT_ID
WITH UR;

-- ----------------------------------------------------------------------------
-- STEP 4: BRONZE CUSTOMERS INGESTION (CDC SIMULATION)
-- Extracts customer updates and captures CDC operation codes.
-- ----------------------------------------------------------------------------
INSERT INTO BRONZE_CUSTOMERS_RAW (
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
    'CUST_DELTA_' || CHAR(YEAR(CURRENT DATE)) || 
    SUBSTR(DIGITS(MONTH(CURRENT DATE)), 9, 2)                     AS INGESTION_BATCH_ID,
    'CRM_LEGACY'                                                  AS SOURCE_SYSTEM_CD,
    CURRENT TIMESTAMP                                             AS EXTRACTED_AT_TS,
    CURRENT TIMESTAMP                                             AS INGESTED_AT_TS,
    'N'                                                           AS RECORD_STATUS
FROM CUSTOMERS C
WITH UR;
