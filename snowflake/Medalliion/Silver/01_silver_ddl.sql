-- ============================================================================
-- SILVER LAYER DDL - SNOWFLAKE (converted from IBM DB2 LUW)
-- ============================================================================
-- Purpose: Conformed, cleansed, and enriched enterprise dimensional model.
-- Implements Slowly Changing Dimension Type 2 (SCD2) for Customers,
-- a conformed product dimension, and enriched analytical fact tables with
-- business rule derivations (SLA flags, delivery lag, stockout risk).
--
-- Converted by SnowConvert 2.51.1-Pr, then hand-repaired. Raw converter output is
-- preserved under artifacts/Medalliion/Silver/01_silver_ddl/deterministic/.
--
-- Repairs applied to the converted output:
--   1. Removed 3 '!!!RESOLVE EWI!!! SSC-EWI-0035' marker lines, which are not
--      valid SQL. The EWI is incorrect - Snowflake supports and enforces CHECK -
--      so all 3 CHECK constraints are retained.
--   2. VALID_TO_TS default was emitted as the DB2 timestamp literal
--      '9999-12-31-23.59.59.999999', which Snowflake cannot parse. Rewritten as
--      '9999-12-31 23:59:59.999999'.
--   3. Qualified all table names as DB2_MIGRATION_2.BIGDATA.
--
-- Note: UNIQUE and PRIMARY KEY constraints below are metadata only in Snowflake
-- and are NOT enforced. UQ_SILVER_PROD_SKU and UQ_SILVER_ORD_NO will therefore
-- not prevent duplicate SKUs or order numbers; the MERGE logic in
-- 02_silver_cleansing_transform.sql is what keeps them unique.
-- ============================================================================

-- Conformed Customer Dimension (SCD Type 2)
CREATE TABLE DB2_MIGRATION_2.BIGDATA.SILVER_DIM_CUSTOMER (
    CUSTOMER_KEY         BIGINT NOT NULL IDENTITY(1000, 1) ORDER,
    CUSTNO               CHAR(6) NOT NULL,
    FIRST_NAME           VARCHAR(30) NOT NULL,
    LAST_NAME            VARCHAR(40) NOT NULL,
    FULL_NAME            VARCHAR(80) NOT NULL,
    STREET_ADDRESS       VARCHAR(80) NOT NULL,
    CITY                 VARCHAR(40) NOT NULL,
    STATE                CHAR(2) NOT NULL,
    REGION               VARCHAR(20) NOT NULL,
    ZIPCODE              VARCHAR(10) NOT NULL,
    SOURCE_SYSTEM_CD     VARCHAR(10) NOT NULL,
    IS_CURRENT           CHAR(1) NOT NULL DEFAULT 'Y',
    VALID_FROM_TS        TIMESTAMP NOT NULL,
    VALID_TO_TS          TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    ROW_HASH             CHAR(32),
    CONSTRAINT PK_SILVER_DIM_CUST PRIMARY KEY (CUSTOMER_KEY),
    CONSTRAINT CK_SILVER_CUST_CURR CHECK (IS_CURRENT IN ('Y', 'N'))
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';

-- Conformed Product Dimension
CREATE TABLE DB2_MIGRATION_2.BIGDATA.SILVER_DIM_PRODUCT (
    PRODUCT_KEY          INTEGER NOT NULL IDENTITY(500, 1) ORDER,
    PRODUCT_ID           INTEGER NOT NULL,
    SKU                  VARCHAR(20) NOT NULL,
    PRODUCT_NAME         VARCHAR(100) NOT NULL,
    CATEGORY             VARCHAR(30) NOT NULL,
    LIST_PRICE           DECIMAL(9,2) NOT NULL,
    PRICE_TIER           VARCHAR(20) NOT NULL,
    IS_ACTIVE            CHAR(1) NOT NULL DEFAULT 'Y',
    SOURCE_SYSTEM_CD     VARCHAR(10) NOT NULL,
    EFFECTIVE_DATE       DATE NOT NULL,
    CONSTRAINT PK_SILVER_DIM_PROD PRIMARY KEY (PRODUCT_KEY),
    CONSTRAINT UQ_SILVER_PROD_SKU UNIQUE (SKU)
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';

-- Cleansed Orders Fact Table
CREATE TABLE DB2_MIGRATION_2.BIGDATA.SILVER_FACT_ORDERS (
    ORDER_KEY            BIGINT NOT NULL IDENTITY(1, 1) ORDER,
    ORDER_NO             CHAR(8) NOT NULL,
    CUSTOMER_KEY         BIGINT NOT NULL,
    CUSTNO               CHAR(6) NOT NULL,
    ORDER_DATE           DATE NOT NULL,
    REQUIRED_DATE        DATE NOT NULL,
    SHIPPED_DATE         DATE,
    DAYS_TO_FULFILL      SMALLINT,
    IS_LATE_FLAG         CHAR(1) NOT NULL DEFAULT 'N',
    ORDER_STATUS         VARCHAR(20) NOT NULL,
    PAYMENT_METHOD       VARCHAR(20) NOT NULL,
    PAYMENT_STATUS       VARCHAR(20) NOT NULL,
    SUBTOTAL             DECIMAL(11,2) NOT NULL,
    TAX_AMOUNT           DECIMAL(9,2) NOT NULL,
    FREIGHT_CHARGE       DECIMAL(9,2) NOT NULL,
    TOTAL_AMOUNT         DECIMAL(11,2) NOT NULL,
    ITEM_COUNT           INTEGER NOT NULL DEFAULT 0,
    TOTAL_UNITS          INTEGER NOT NULL DEFAULT 0,
    INGESTION_BATCH_ID   VARCHAR(50) NOT NULL,
    CLEANSED_AT_TS       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_SILVER_FACT_ORD PRIMARY KEY (ORDER_KEY),
    CONSTRAINT UQ_SILVER_ORD_NO UNIQUE (ORDER_NO),
    CONSTRAINT CK_SILVER_ORD_LATE CHECK (IS_LATE_FLAG IN ('Y', 'N'))
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';

-- Cleansed Inventory Snapshot Fact Table
CREATE TABLE DB2_MIGRATION_2.BIGDATA.SILVER_FACT_INVENTORY_DAILY (
    INVENTORY_KEY        BIGINT NOT NULL IDENTITY(1, 1) ORDER,
    SNAPSHOT_DATE        DATE NOT NULL,
    WAREHOUSE_ID         CHAR(4) NOT NULL,
    PRODUCT_KEY          INTEGER NOT NULL,
    SKU                  VARCHAR(20) NOT NULL,
    ON_HAND_QTY          INTEGER NOT NULL,
    ALLOCATED_QTY        INTEGER NOT NULL,
    AVAILABLE_QTY        INTEGER NOT NULL,
    REORDER_POINT        INTEGER NOT NULL,
    REORDER_QTY          INTEGER NOT NULL,
    SAFETY_STOCK         INTEGER NOT NULL,
    STOCKOUT_RISK_FLAG   CHAR(1) NOT NULL DEFAULT 'N',
    STOCK_HEALTH_STATUS  VARCHAR(20) NOT NULL,
    BIN_LOCATION         VARCHAR(20) NOT NULL,
    LAST_RESTOCK_DATE    DATE,
    CLEANSED_AT_TS       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_SILVER_FACT_INV PRIMARY KEY (INVENTORY_KEY),
    CONSTRAINT CK_SILVER_INV_RISK CHECK (STOCKOUT_RISK_FLAG IN ('Y', 'N'))
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';
