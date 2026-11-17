-- ============================================================================
-- BRONZE LAYER DDL - SNOWFLAKE (converted from IBM DB2 LUW)
-- ============================================================================
-- Purpose: Raw ingestion landing tables mirroring source OLTP / CDC / flat files.
-- Includes raw audit metadata columns (Batch IDs, extraction timestamps, source codes).
--
-- Converted by SnowConvert 2.51.1-Pr, then hand-repaired. Raw converter output is
-- preserved under artifacts/Medalliion/Bronze/01_bronze_ddl/deterministic/.
--
-- Repairs applied to the converted output:
--   1. Removed 4 '!!!RESOLVE EWI!!! SSC-EWI-0035 CHECK STATEMENT NOT SUPPORTED'
--      marker lines. The markers are not valid SQL. The EWI itself is incorrect:
--      Snowflake supports AND enforces CHECK constraints. All 4 CHECK constraints
--      below are retained deliberately.
--   2. Qualified all table names as DB2_MIGRATION_2.BIGDATA so the script runs
--      without a USE SCHEMA step.
--
-- Functional difference carried over from conversion:
--   DB2 'GENERATED ALWAYS AS IDENTITY' became Snowflake 'IDENTITY'. Snowflake has
--   no GENERATED ALWAYS equivalent, so explicit inserts into these surrogate keys
--   are now possible where DB2 rejected them.
-- ============================================================================

-- Raw Orders Staging Table
CREATE TABLE DB2_MIGRATION_2.BIGDATA.BRONZE_ORDERS_RAW (
    BRONZE_ORDER_ID      BIGINT NOT NULL IDENTITY(1, 1) ORDER,
    RAW_ORDER_NO         VARCHAR(20),
    RAW_CUSTNO           VARCHAR(20),
    RAW_ORDER_DATE       VARCHAR(30),
    RAW_REQUIRED_DATE    VARCHAR(30),
    RAW_SHIPPED_DATE     VARCHAR(30),
    RAW_STATUS           VARCHAR(30),
    RAW_SUBTOTAL         VARCHAR(30),
    RAW_TAX_AMOUNT       VARCHAR(30),
    RAW_FREIGHT_CHARGE   VARCHAR(30),
    RAW_TOTAL_AMOUNT     VARCHAR(30),
    RAW_PAYMENT_METHOD   VARCHAR(30),
    RAW_PAYMENT_STATUS   VARCHAR(30),
    -- Enterprise Ingestion Metadata Columns
    INGESTION_BATCH_ID   VARCHAR(50) NOT NULL,
    SOURCE_SYSTEM_CD     VARCHAR(10) NOT NULL DEFAULT 'DB2_OLTP',
    EXTRACTED_AT_TS      TIMESTAMP NOT NULL,
    INGESTED_AT_TS       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    RECORD_STATUS        CHAR(1) NOT NULL DEFAULT 'N',   -- 'N': New, 'P': Processed, 'E': Error
    ERROR_DESCRIPTION    VARCHAR(255),
    CONSTRAINT PK_BRONZE_ORDERS PRIMARY KEY (BRONZE_ORDER_ID),
    CONSTRAINT CK_BRONZE_ORD_STAT CHECK (RECORD_STATUS IN ('N', 'P', 'E'))
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';

-- Raw Order Line Items Staging Table
CREATE TABLE DB2_MIGRATION_2.BIGDATA.BRONZE_ORDER_ITEMS_RAW (
    BRONZE_ITEM_ID       BIGINT NOT NULL IDENTITY(1, 1) ORDER,
    RAW_ORDER_NO         VARCHAR(20),
    RAW_LINE_NO          VARCHAR(10),
    RAW_SKU              VARCHAR(30),
    RAW_QUANTITY         VARCHAR(20),
    RAW_UNIT_PRICE       VARCHAR(30),
    RAW_DISCOUNT_PCT     VARCHAR(20),
    RAW_EXTENDED_PRICE   VARCHAR(30),
    -- Enterprise Ingestion Metadata Columns
    INGESTION_BATCH_ID   VARCHAR(50) NOT NULL,
    SOURCE_SYSTEM_CD     VARCHAR(10) NOT NULL DEFAULT 'DB2_OLTP',
    EXTRACTED_AT_TS      TIMESTAMP NOT NULL,
    INGESTED_AT_TS       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    RECORD_STATUS        CHAR(1) NOT NULL DEFAULT 'N',
    ERROR_DESCRIPTION    VARCHAR(255),
    CONSTRAINT PK_BRONZE_ITEMS PRIMARY KEY (BRONZE_ITEM_ID),
    CONSTRAINT CK_BRONZE_ITM_STAT CHECK (RECORD_STATUS IN ('N', 'P', 'E'))
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';

-- Raw Inventory Snapshot Staging Table
CREATE TABLE DB2_MIGRATION_2.BIGDATA.BRONZE_INVENTORY_RAW (
    BRONZE_INV_ID        BIGINT NOT NULL IDENTITY(1, 1) ORDER,
    RAW_WAREHOUSE_ID     VARCHAR(10),
    RAW_SKU              VARCHAR(30),
    RAW_ON_HAND_QTY      VARCHAR(20),
    RAW_ALLOCATED_QTY    VARCHAR(20),
    RAW_REORDER_POINT    VARCHAR(20),
    RAW_REORDER_QTY      VARCHAR(20),
    RAW_SAFETY_STOCK     VARCHAR(20),
    RAW_BIN_LOCATION     VARCHAR(30),
    RAW_LAST_RESTOCK_DT  VARCHAR(30),
    -- Enterprise Ingestion Metadata Columns
    INGESTION_BATCH_ID   VARCHAR(50) NOT NULL,
    SOURCE_SYSTEM_CD     VARCHAR(10) NOT NULL DEFAULT 'WMS_MAIN',
    EXTRACTED_AT_TS      TIMESTAMP NOT NULL,
    INGESTED_AT_TS       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    RECORD_STATUS        CHAR(1) NOT NULL DEFAULT 'N',
    ERROR_DESCRIPTION    VARCHAR(255),
    CONSTRAINT PK_BRONZE_INV PRIMARY KEY (BRONZE_INV_ID),
    CONSTRAINT CK_BRONZE_INV_STAT CHECK (RECORD_STATUS IN ('N', 'P', 'E'))
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';

-- Raw Customer Master Staging Table
CREATE TABLE DB2_MIGRATION_2.BIGDATA.BRONZE_CUSTOMERS_RAW (
    BRONZE_CUST_ID       BIGINT NOT NULL IDENTITY(1, 1) ORDER,
    RAW_CUSTNO           VARCHAR(20),
    RAW_FNAME            VARCHAR(50),
    RAW_LNAME            VARCHAR(60),
    RAW_ADDR             VARCHAR(100),
    RAW_CITY             VARCHAR(50),
    RAW_STATE            VARCHAR(10),
    RAW_ZIPCODE          VARCHAR(20),
    RAW_PHONE            VARCHAR(30),
    RAW_OP_TYPE          CHAR(1) DEFAULT 'I',   -- CDC operation: 'I'=Insert, 'U'=Update, 'D'=Delete
    -- Enterprise Ingestion Metadata Columns
    INGESTION_BATCH_ID   VARCHAR(50) NOT NULL,
    SOURCE_SYSTEM_CD     VARCHAR(10) NOT NULL DEFAULT 'CRM_LEGACY',
    EXTRACTED_AT_TS      TIMESTAMP NOT NULL,
    INGESTED_AT_TS       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    RECORD_STATUS        CHAR(1) NOT NULL DEFAULT 'N',
    CONSTRAINT PK_BRONZE_CUST PRIMARY KEY (BRONZE_CUST_ID),
    CONSTRAINT CK_BRONZE_CUST_STAT CHECK (RECORD_STATUS IN ('N', 'P', 'E'))
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/16/2026",  "domain": "no-domain-provided",  "migrationid": "lOShAdvmDnqnRwvBjfuipQ==" }}';
