-- ============================================================================
-- SILVER LAYER CLEANSING & CONFORMATION TRANSFORMATIONS - IBM DB2 LUW
-- ============================================================================
-- Purpose: Performs heavy cleaning, normalization, surrogate key mapping,
-- analytical deduplication, and SCD2 dimension updates.
-- Uses legacy DB2 LUW constructs:
--   - ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) for CDC deduplication
--   - DAYS() scalar function for date difference arithmetic
--   - MERGE INTO statements for idempotent upserts
--   - VALUE / COALESCE for null handling
--   - String concats (||), UPPER(), RTRIM(), LTRIM()
--   - Isolation clause WITH UR for non-blocking read access
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: CONFORM PRODUCT DIMENSION
-- Populates SILVER_DIM_PRODUCT from operational PRODUCTS and assigns Price Tiers.
-- ----------------------------------------------------------------------------
--** SSC-FDM-0007 - MISSING DEPENDENT OBJECT "PRODUCTS" **
MERGE INTO DB2_MIGRATION_2.BIGDATA.SILVER_DIM_PRODUCT TGT
USING (
    SELECT
        P.PRODUCT_ID,
        RTRIM(P.SKU) AS SKU,
        RTRIM(P.PRODUCT_NAME) AS PRODUCT_NAME,
        RTRIM(P.CATEGORY) AS CATEGORY,
        P.LIST_PRICE,
        CASE
            WHEN P.LIST_PRICE >= 500.00 THEN 'TIER_1_ENTERPRISE'
            WHEN P.LIST_PRICE >= 150.00 THEN 'TIER_2_MIDRANGE'
            ELSE 'TIER_3_STANDARD'
        END AS PRICE_TIER,
        P.ACTIVE_FLAG AS IS_ACTIVE,
        'DB2_OLTP' AS SOURCE_SYSTEM_CD,
        CURRENT_DATE() AS EFFECTIVE_DATE
    FROM DB2_MIGRATION_2.BIGDATA.PRODUCTS P
) SRC
ON (TGT.SKU = SRC.SKU)
WHEN MATCHED THEN
    UPDATE SET
        TGT.PRODUCT_NAME   = SRC.PRODUCT_NAME,
        TGT.CATEGORY       = SRC.CATEGORY,
        TGT.LIST_PRICE     = SRC.LIST_PRICE,
        TGT.PRICE_TIER     = SRC.PRICE_TIER,
        TGT.IS_ACTIVE      = SRC.IS_ACTIVE,
        TGT.EFFECTIVE_DATE = SRC.EFFECTIVE_DATE
WHEN NOT MATCHED THEN
    INSERT (
        PRODUCT_ID,
        SKU,
        PRODUCT_NAME,
        CATEGORY,
        LIST_PRICE,
        PRICE_TIER,
        IS_ACTIVE,
        SOURCE_SYSTEM_CD,
        EFFECTIVE_DATE
    ) VALUES (
        SRC.PRODUCT_ID,
        SRC.SKU,
        SRC.PRODUCT_NAME,
        SRC.CATEGORY,
        SRC.LIST_PRICE,
        SRC.PRICE_TIER,
        SRC.IS_ACTIVE,
        SRC.SOURCE_SYSTEM_CD,
        SRC.EFFECTIVE_DATE
    );

-- ----------------------------------------------------------------------------
-- STEP 2: CONFORM CUSTOMER DIMENSION (SCD TYPE 2 PROCESSING)
-- Cleans names, standardizes states, derives geographic sales regions.
-- Uses DB2 Common Table Expressions and window functions to select latest CDC row.
-- ----------------------------------------------------------------------------
MERGE INTO DB2_MIGRATION_2.BIGDATA.SILVER_DIM_CUSTOMER TGT
USING (
    WITH CTE_DEDUP_BRONZE AS (
        SELECT
            RAW_CUSTNO,
            RAW_FNAME,
            RAW_LNAME,
            RAW_ADDR,
            RAW_CITY,
            RAW_STATE,
            RAW_ZIPCODE,
            SOURCE_SYSTEM_CD,
            EXTRACTED_AT_TS,
            ROW_NUMBER() OVER (
                PARTITION BY RAW_CUSTNO
                ORDER BY EXTRACTED_AT_TS DESC, BRONZE_CUST_ID DESC
            ) AS DEDUP_RANK
        FROM DB2_MIGRATION_2.BIGDATA.BRONZE_CUSTOMERS_RAW
        WHERE RAW_CUSTNO IS NOT NULL
    )
    SELECT
        D.RAW_CUSTNO                                              AS CUSTNO,
        RTRIM(D.RAW_FNAME)                                        AS FIRST_NAME,
        RTRIM(D.RAW_LNAME)                                        AS LAST_NAME,
        RTRIM(D.RAW_FNAME) || ' ' || RTRIM(D.RAW_LNAME)           AS FULL_NAME,
        RTRIM(D.RAW_ADDR)                                         AS STREET_ADDRESS,
        RTRIM(D.RAW_CITY)                                         AS CITY,
        UPPER(RTRIM(D.RAW_STATE))                                 AS STATE,
        CASE
            WHEN UPPER(RTRIM(D.RAW_STATE)) IN ('CA', 'OR', 'WA')             THEN 'WEST'
            WHEN UPPER(RTRIM(D.RAW_STATE)) IN ('TX', 'FL', 'GA', 'AL', 'AR') THEN 'SOUTH'
            WHEN UPPER(RTRIM(D.RAW_STATE)) IN ('IL', 'MI', 'OH', 'MN')       THEN 'MIDWEST'
            WHEN UPPER(RTRIM(D.RAW_STATE)) IN ('NY', 'NJ', 'PA', 'NH')       THEN 'NORTHEAST'
            ELSE 'OTHER'
        END                                                       AS REGION,
        RTRIM(D.RAW_ZIPCODE)                                      AS ZIPCODE,
        D.SOURCE_SYSTEM_CD,
        D.EXTRACTED_AT_TS                                         AS VALID_FROM_TS
    FROM CTE_DEDUP_BRONZE D
    WHERE D.DEDUP_RANK = 1
) SRC
ON (TGT.CUSTNO = SRC.CUSTNO AND TGT.IS_CURRENT = 'Y')
WHEN MATCHED AND (
    TGT.STREET_ADDRESS <> SRC.STREET_ADDRESS OR
    TGT.CITY           <> SRC.CITY OR
    TGT.STATE          <> SRC.STATE OR
    TGT.ZIPCODE        <> SRC.ZIPCODE
) THEN
    -- In full SCD2, existing row is expired and new row is inserted.
    UPDATE SET
        TGT.IS_CURRENT   = 'N',
        TGT.VALID_TO_TS  = DATEADD(microsecond, -1, SRC.VALID_FROM_TS)
WHEN NOT MATCHED THEN
    INSERT (
        CUSTNO,
        FIRST_NAME,
        LAST_NAME,
        FULL_NAME,
        STREET_ADDRESS,
        CITY,
        STATE,
        REGION,
        ZIPCODE,
        SOURCE_SYSTEM_CD,
        IS_CURRENT,
        VALID_FROM_TS
    ) VALUES (
        SRC.CUSTNO,
        SRC.FIRST_NAME,
        SRC.LAST_NAME,
        SRC.FULL_NAME,
        SRC.STREET_ADDRESS,
        SRC.CITY,
        SRC.STATE,
        SRC.REGION,
        SRC.ZIPCODE,
        SRC.SOURCE_SYSTEM_CD,
        'Y',
        SRC.VALID_FROM_TS
    );

-- Insert newly versioned rows for expired SCD2 records
INSERT INTO DB2_MIGRATION_2.BIGDATA.SILVER_DIM_CUSTOMER (
    CUSTNO,
    FIRST_NAME,
    LAST_NAME,
    FULL_NAME,
    STREET_ADDRESS,
    CITY,
    STATE,
    REGION,
    ZIPCODE,
    SOURCE_SYSTEM_CD,
    IS_CURRENT,
    VALID_FROM_TS
)
SELECT
    SRC.CUSTNO,
    SRC.FIRST_NAME,
    SRC.LAST_NAME,
    SRC.FULL_NAME,
    SRC.STREET_ADDRESS,
    SRC.CITY,
    SRC.STATE,
    SRC.REGION,
    SRC.ZIPCODE,
    SRC.SOURCE_SYSTEM_CD,
    'Y',
    SRC.VALID_FROM_TS
FROM (
    SELECT
            RTRIM(RAW_CUSTNO)                                        AS CUSTNO,
            RTRIM(RAW_FNAME)                                         AS FIRST_NAME,
            RTRIM(RAW_LNAME)                                         AS LAST_NAME,
            RTRIM(RAW_FNAME) || ' ' || RTRIM(RAW_LNAME)              AS FULL_NAME,
            RTRIM(RAW_ADDR)                                          AS STREET_ADDRESS,
            RTRIM(RAW_CITY)                                          AS CITY,
            UPPER(RTRIM(RAW_STATE))                                  AS STATE,
        CASE
            WHEN UPPER(RTRIM(RAW_STATE)) IN ('CA', 'OR', 'WA')             THEN 'WEST'
            WHEN UPPER(RTRIM(RAW_STATE)) IN ('TX', 'FL', 'GA', 'AL', 'AR') THEN 'SOUTH'
            WHEN UPPER(RTRIM(RAW_STATE)) IN ('IL', 'MI', 'OH', 'MN')       THEN 'MIDWEST'
            WHEN UPPER(RTRIM(RAW_STATE)) IN ('NY', 'NJ', 'PA', 'NH')       THEN 'NORTHEAST'
            ELSE 'OTHER'
        END                                                      AS REGION,
            RTRIM(RAW_ZIPCODE)                                       AS ZIPCODE,
        SOURCE_SYSTEM_CD,
        EXTRACTED_AT_TS                                          AS VALID_FROM_TS,
            ROW_NUMBER() OVER (PARTITION BY RAW_CUSTNO ORDER BY EXTRACTED_AT_TS DESC) AS RN
    FROM DB2_MIGRATION_2.BIGDATA.BRONZE_CUSTOMERS_RAW
    ) SRC
WHERE SRC.RN = 1
  AND NOT EXISTS (
      SELECT 1 FROM DB2_MIGRATION_2.BIGDATA.SILVER_DIM_CUSTOMER CURR
      WHERE CURR.CUSTNO = SRC.CUSTNO AND CURR.IS_CURRENT = 'Y'
  );

-- ----------------------------------------------------------------------------
-- STEP 3: CLEANSING & TRANSFORMATION OF FACT ORDERS
-- Deduplicates Bronze Orders, aggregates line items from Bronze Order Items,
-- calculates fulfillment cycle duration via DAYS() difference, and flags SLA violations.
-- ----------------------------------------------------------------------------
MERGE INTO DB2_MIGRATION_2.BIGDATA.SILVER_FACT_ORDERS TGT
USING (
    WITH CTE_DEDUP_ORDERS AS (
        SELECT
            RAW_ORDER_NO,
            RAW_CUSTNO,
            TO_DATE(RAW_ORDER_DATE, 'YYYY-MM-DD')                                  AS ORDER_DATE,
            TO_DATE(RAW_REQUIRED_DATE, 'YYYY-MM-DD')                               AS REQUIRED_DATE,
            CASE
                WHEN RAW_SHIPPED_DATE IS NOT NULL AND RAW_SHIPPED_DATE <> ''
                     THEN TO_DATE(RAW_SHIPPED_DATE, 'YYYY-MM-DD')
                ELSE NULL
            END                                                   AS SHIPPED_DATE,
            RAW_STATUS,
            RAW_PAYMENT_METHOD,
            RAW_PAYMENT_STATUS,
            CAST(RAW_SUBTOTAL AS NUMBER(11,2))                          AS SUBTOTAL,
            CAST(RAW_TAX_AMOUNT AS NUMBER(9,2))                         AS TAX_AMOUNT,
            CAST(RAW_FREIGHT_CHARGE AS NUMBER(9,2))                     AS FREIGHT_CHARGE,
            CAST(RAW_TOTAL_AMOUNT AS NUMBER(11,2))                      AS TOTAL_AMOUNT,
            INGESTION_BATCH_ID,
            ROW_NUMBER() OVER (
                PARTITION BY RAW_ORDER_NO
                ORDER BY EXTRACTED_AT_TS DESC
            ) AS ORD_RANK
        FROM DB2_MIGRATION_2.BIGDATA.BRONZE_ORDERS_RAW
    ),
    CTE_AGG_ITEMS AS (
        SELECT
            RAW_ORDER_NO,
            COUNT(*)                                              AS ITEM_COUNT,
            SUM(CAST(RAW_QUANTITY AS INTEGER))                            AS TOTAL_UNITS
        FROM DB2_MIGRATION_2.BIGDATA.BRONZE_ORDER_ITEMS_RAW
        GROUP BY RAW_ORDER_NO
    )
    SELECT
        O.RAW_ORDER_NO                                            AS ORDER_NO,
        C.CUSTOMER_KEY,
        O.RAW_CUSTNO                                              AS CUSTNO,
        O.ORDER_DATE,
        O.REQUIRED_DATE,
        O.SHIPPED_DATE,
        CASE
            WHEN O.SHIPPED_DATE IS NOT NULL
                 THEN DATEDIFF(day, O.ORDER_DATE, O.SHIPPED_DATE)
            ELSE NULL
        END                                                       AS DAYS_TO_FULFILL,
        CASE
            WHEN O.SHIPPED_DATE IS NOT NULL AND O.SHIPPED_DATE > O.REQUIRED_DATE
                 THEN 'Y'
            WHEN O.SHIPPED_DATE IS NULL AND CURRENT_DATE() > O.REQUIRED_DATE
                 THEN 'Y'
            ELSE 'N'
        END                                                       AS IS_LATE_FLAG,
        O.RAW_STATUS                                              AS ORDER_STATUS,
        O.RAW_PAYMENT_METHOD                                      AS PAYMENT_METHOD,
        O.RAW_PAYMENT_STATUS                                      AS PAYMENT_STATUS,
        O.SUBTOTAL,
        O.TAX_AMOUNT,
        O.FREIGHT_CHARGE,
        O.TOTAL_AMOUNT,
        COALESCE(I.ITEM_COUNT, 0)                                    AS ITEM_COUNT,
        COALESCE(I.TOTAL_UNITS, 0)                                   AS TOTAL_UNITS,
        O.INGESTION_BATCH_ID
    FROM CTE_DEDUP_ORDERS O
    INNER JOIN DB2_MIGRATION_2.BIGDATA.SILVER_DIM_CUSTOMER C
        ON C.CUSTNO = O.RAW_CUSTNO AND C.IS_CURRENT = 'Y'
    LEFT OUTER JOIN CTE_AGG_ITEMS I
        ON I.RAW_ORDER_NO = O.RAW_ORDER_NO
    WHERE O.ORD_RANK = 1
) SRC
ON (TGT.ORDER_NO = SRC.ORDER_NO)
WHEN MATCHED THEN
    UPDATE SET
        TGT.SHIPPED_DATE    = SRC.SHIPPED_DATE,
        TGT.DAYS_TO_FULFILL = SRC.DAYS_TO_FULFILL,
        TGT.IS_LATE_FLAG    = SRC.IS_LATE_FLAG,
        TGT.ORDER_STATUS    = SRC.ORDER_STATUS,
        TGT.PAYMENT_STATUS  = SRC.PAYMENT_STATUS,
        TGT.TOTAL_AMOUNT    = SRC.TOTAL_AMOUNT,
        TGT.ITEM_COUNT      = SRC.ITEM_COUNT,
        TGT.TOTAL_UNITS     = SRC.TOTAL_UNITS,
        TGT.CLEANSED_AT_TS  = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
    INSERT (
        ORDER_NO,
        CUSTOMER_KEY,
        CUSTNO,
        ORDER_DATE,
        REQUIRED_DATE,
        SHIPPED_DATE,
        DAYS_TO_FULFILL,
        IS_LATE_FLAG,
        ORDER_STATUS,
        PAYMENT_METHOD,
        PAYMENT_STATUS,
        SUBTOTAL,
        TAX_AMOUNT,
        FREIGHT_CHARGE,
        TOTAL_AMOUNT,
        ITEM_COUNT,
        TOTAL_UNITS,
        INGESTION_BATCH_ID,
        CLEANSED_AT_TS
    ) VALUES (
        SRC.ORDER_NO,
        SRC.CUSTOMER_KEY,
        SRC.CUSTNO,
        SRC.ORDER_DATE,
        SRC.REQUIRED_DATE,
        SRC.SHIPPED_DATE,
        SRC.DAYS_TO_FULFILL,
        SRC.IS_LATE_FLAG,
        SRC.ORDER_STATUS,
        SRC.PAYMENT_METHOD,
        SRC.PAYMENT_STATUS,
        SRC.SUBTOTAL,
        SRC.TAX_AMOUNT,
        SRC.FREIGHT_CHARGE,
        SRC.TOTAL_AMOUNT,
        SRC.ITEM_COUNT,
        SRC.TOTAL_UNITS,
        SRC.INGESTION_BATCH_ID,
        CURRENT_TIMESTAMP()
    );

-- ----------------------------------------------------------------------------
-- STEP 4: CLEANSING & TRANSFORMATION OF FACT INVENTORY DAILY
-- Calculates stock availability, computes stockout risks, categorizes inventory health.
-- ----------------------------------------------------------------------------
INSERT INTO DB2_MIGRATION_2.BIGDATA.SILVER_FACT_INVENTORY_DAILY (
    SNAPSHOT_DATE,
    WAREHOUSE_ID,
    PRODUCT_KEY,
    SKU,
    ON_HAND_QTY,
    ALLOCATED_QTY,
    AVAILABLE_QTY,
    REORDER_POINT,
    REORDER_QTY,
    SAFETY_STOCK,
    STOCKOUT_RISK_FLAG,
    STOCK_HEALTH_STATUS,
    BIN_LOCATION,
    LAST_RESTOCK_DATE,
    CLEANSED_AT_TS
)
SELECT
    CURRENT_DATE() AS SNAPSHOT_DATE,
    RTRIM(B.RAW_WAREHOUSE_ID)                                     AS WAREHOUSE_ID,
    P.PRODUCT_KEY,
    RTRIM(B.RAW_SKU)                                              AS SKU,
    CAST(B.RAW_ON_HAND_QTY AS INTEGER)                                    AS ON_HAND_QTY,
    CAST(B.RAW_ALLOCATED_QTY AS INTEGER)                                  AS ALLOCATED_QTY,
    CAST(B.RAW_ON_HAND_QTY AS INTEGER) - CAST(B.RAW_ALLOCATED_QTY AS INTEGER)     AS AVAILABLE_QTY,
    CAST(B.RAW_REORDER_POINT AS INTEGER)                                  AS REORDER_POINT,
    CAST(B.RAW_REORDER_QTY AS INTEGER)                                    AS REORDER_QTY,
    CAST(B.RAW_SAFETY_STOCK AS INTEGER)                                   AS SAFETY_STOCK,
    CASE
        WHEN (CAST(B.RAW_ON_HAND_QTY AS INTEGER) - CAST(B.RAW_ALLOCATED_QTY AS INTEGER)) <= CAST(B.RAW_SAFETY_STOCK AS INTEGER)
             THEN 'Y'
        ELSE 'N'
    END                                                           AS STOCKOUT_RISK_FLAG,
    CASE
        WHEN (CAST(B.RAW_ON_HAND_QTY AS INTEGER) - CAST(B.RAW_ALLOCATED_QTY AS INTEGER)) <= CAST(B.RAW_SAFETY_STOCK AS INTEGER)
             THEN 'CRITICAL_DEFICIT'
        WHEN (CAST(B.RAW_ON_HAND_QTY AS INTEGER) - CAST(B.RAW_ALLOCATED_QTY AS INTEGER)) <= CAST(B.RAW_REORDER_POINT AS INTEGER)
             THEN 'REORDER_TRIGGERED'
        WHEN (CAST(B.RAW_ON_HAND_QTY AS INTEGER) - CAST(B.RAW_ALLOCATED_QTY AS INTEGER)) > (CAST(B.RAW_REORDER_POINT AS INTEGER) * 3)
             THEN 'OVERSTOCKED'
        ELSE 'OPTIMAL'
    END                                                           AS STOCK_HEALTH_STATUS,
    RTRIM(B.RAW_BIN_LOCATION)                                     AS BIN_LOCATION,
    CASE
        WHEN B.RAW_LAST_RESTOCK_DT IS NOT NULL AND B.RAW_LAST_RESTOCK_DT <> '1900-01-01'
             THEN TO_DATE(B.RAW_LAST_RESTOCK_DT, 'YYYY-MM-DD')
        ELSE NULL
    END                                                           AS LAST_RESTOCK_DATE,
    CURRENT_TIMESTAMP() AS CLEANSED_AT_TS
FROM DB2_MIGRATION_2.BIGDATA.BRONZE_INVENTORY_RAW B
INNER JOIN DB2_MIGRATION_2.BIGDATA.SILVER_DIM_PRODUCT P
    ON P.SKU = RTRIM(B.RAW_SKU)
WHERE B.BRONZE_INV_ID IN (
    SELECT
             MAX(BRONZE_INV_ID)
    FROM DB2_MIGRATION_2.BIGDATA.BRONZE_INVENTORY_RAW
        GROUP BY RAW_WAREHOUSE_ID, RAW_SKU
);