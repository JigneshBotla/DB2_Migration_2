-- This CLP file was created using DB2LOOK Version "12.1" 
-- Timestamp: Tue Nov 10 13:52:00 2026
-- Database Name: TESTDB         
-- Database Manager Version: DB2/LINUXX8664 Version 12.1.5.0
-- Database Codepage: 1208
-- Database Collating Sequence is: IDENTITY
-- Alternate collating sequence(alt_collate): null
-- varchar2 compatibility(varchar2_compat): OFF


CONNECT TO TESTDB !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'ToConnectionTarget' NODE ***/!!!;

------------------------------------------------
-- DDL Statements for Schemas
------------------------------------------------


CREATE SCHEMA "BIGDATA" AUTHORIZATION "DB2INST1" !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'CreateSchema' NODE ***/!!!;
---------------------------------
-- DDL Statements for Sequences
---------------------------------
!!!RESOLVE EWI!!! /*** SSC-EWI-0120 - SEQUENCE OPTIONS 'MIN VALUE, MAX VALUE, CYCLE' WERE REMOVED, THEY ARE NOT SUPPORTED IN SNOWFLAKE ***/!!!
	CREATE SEQUENCE "BIGDATA"."SEQ_AUDIT_BATCH"
	START WITH 1 INCREMENT BY 1
	ORDER
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';
!!!RESOLVE EWI!!! /*** SSC-EWI-0120 - SEQUENCE OPTIONS 'MIN VALUE, MAX VALUE' WERE REMOVED, THEY ARE NOT SUPPORTED IN SNOWFLAKE ***/!!!
CREATE SEQUENCE "BIGDATA"."SEQ_INVOICE_NO"
	START WITH 62358 INCREMENT BY 1
	NOORDER
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';



------------------------------------------------
-- DDL Statements for Table "BIGDATA"."CUSTOMERS"
------------------------------------------------
CREATE TABLE "BIGDATA"."CUSTOMERS" (
		  "CUSTNO" CHAR(6) NOT NULL,
		  "FNAME" CHAR(20) NOT NULL,
		  "LNAME" CHAR(30) NOT NULL,
		  "ADDR" CHAR(30) NOT NULL,
		  "CITY" CHAR(20) NOT NULL,
		  "STATE" CHAR(2) NOT NULL,
		  "ZIPCODE" CHAR(10) NOT NULL )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."CUSTOMERS"
ALTER TABLE "BIGDATA"."CUSTOMERS"
	ADD CONSTRAINT "CUSTNO_PK" PRIMARY KEY
		("CUSTNO")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "BIGDATA"."INVOICES"
------------------------------------------------
CREATE TABLE "BIGDATA"."INVOICES" (
		  "INVCUST" CHAR(6) NOT NULL,
		  "INVNO" CHAR(6) NOT NULL,
		  "INVDATE" DATE NOT NULL,
		  "INVSUBT" DECIMAL(9,2) NOT NULL,
		  "INVSHIP" DECIMAL(7,2) NOT NULL,
		  "INVTAX" DECIMAL(7,2) NOT NULL,
		  "INVTOTAL" DECIMAL(9,2) NOT NULL,
		  "INVPROM" CHAR(10) NOT NULL )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."INVOICES"
ALTER TABLE "BIGDATA"."INVOICES"
	ADD CONSTRAINT "INVNO_PK" PRIMARY KEY
		("INVNO")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "BIGDATA"."PROMOTIONS"
------------------------------------------------
CREATE TABLE "BIGDATA"."PROMOTIONS" (
		  "PROMO_CODE" CHAR(10) NOT NULL,
		  "PROMO_NAME" VARCHAR(60) NOT NULL,
		  "DISCOUNT_PCT" DECIMAL(5,2) NOT NULL,
		  "START_DATE" DATE NOT NULL,
		  "END_DATE" DATE )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."PROMOTIONS"
ALTER TABLE "BIGDATA"."PROMOTIONS"
	ADD CONSTRAINT "PROMOTIONS_PK" PRIMARY KEY
		("PROMO_CODE")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "BIGDATA"."PRODUCTS"
------------------------------------------------
CREATE TABLE "BIGDATA"."PRODUCTS" (
		  "PRODUCT_ID" INTEGER NOT NULL IDENTITY(+1000, +1) ORDER,
		  "SKU" VARCHAR(20) NOT NULL,
		  "PRODUCT_NAME" VARCHAR(100) NOT NULL,
		  "CATEGORY" VARCHAR(30) NOT NULL,
		  "LIST_PRICE" DECIMAL(9,2) NOT NULL,
		  "ACTIVE_FLAG" CHAR(1) NOT NULL DEFAULT 'Y',
		  "CREATED_TS" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
		  "DESCRIPTION" VARCHAR
)
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."PRODUCTS"
ALTER TABLE "BIGDATA"."PRODUCTS"
	ADD CONSTRAINT "PRODUCTS_PK" PRIMARY KEY
		("PRODUCT_ID")
	ENFORCED;


-- DDL Statements for Unique Constraints on Table "BIGDATA"."PRODUCTS"
ALTER TABLE "BIGDATA"."PRODUCTS"
	ADD CONSTRAINT "PRODUCTS_SKU_UQ" UNIQUE
		("SKU")
	ENFORCED;
ALTER TABLE "BIGDATA"."PRODUCTS"
ALTER COLUMN "PRODUCT_ID" RESTART WITH 6000 !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'AlterColumnDefinition' NODE ***/!!!;

------------------------------------------------
-- DDL Statements for Table "BIGDATA"."INVOICE_LINES"
------------------------------------------------
CREATE TABLE "BIGDATA"."INVOICE_LINES" (
		  "LINE_ID" INTEGER NOT NULL IDENTITY(+1, +1) ORDER,
		  "INVNO" CHAR(6) NOT NULL,
		  "LINE_NO" SMALLINT NOT NULL,
		  "PRODUCT_ID" INTEGER NOT NULL,
		  "QUANTITY" INTEGER NOT NULL,
		  "UNIT_PRICE" DECIMAL(9,2) NOT NULL,
		  "LINE_TOTAL" DECIMAL(11,2) NOT NULL )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."INVOICE_LINES"
ALTER TABLE "BIGDATA"."INVOICE_LINES"
	ADD CONSTRAINT "LINES_PK" PRIMARY KEY
		("LINE_ID")
	ENFORCED;


-- DDL Statements for Unique Constraints on Table "BIGDATA"."INVOICE_LINES"
ALTER TABLE "BIGDATA"."INVOICE_LINES"
	ADD CONSTRAINT "LINES_INV_LINE_UQ" UNIQUE
		("INVNO",
		 "LINE_NO")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "BIGDATA"."CUSTOMER_AUDIT"
------------------------------------------------
CREATE TABLE "BIGDATA"."CUSTOMER_AUDIT" (
		  "AUDIT_ID" INTEGER NOT NULL IDENTITY(+1, +1) ORDER,
		  "CUSTNO" CHAR(6) NOT NULL,
		  "ACTION_CD" CHAR(1) NOT NULL,
		  "ACTION_TS" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
		  "ACTION_USER" VARCHAR(128) NOT NULL DEFAULT CURRENT_USER(),
		  "NOTES" VARCHAR(200) )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."CUSTOMER_AUDIT"
ALTER TABLE "BIGDATA"."CUSTOMER_AUDIT"
	ADD CONSTRAINT "AUDIT_PK" PRIMARY KEY
		("AUDIT_ID")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "BIGDATA"."CUSTOMER_SALES_SUMMARY"
------------------------------------------------
CREATE TABLE "BIGDATA"."CUSTOMER_SALES_SUMMARY" (
		  "CUSTNO" CHAR(6) NOT NULL,
		  "INVOICE_COUNT" INTEGER NOT NULL,
		  "TOTAL_SALES" DECIMAL(11,2) NOT NULL,
		  "LAST_INVOICE_DATE" DATE,
		  "REFRESHED_TS" TIMESTAMP NOT NULL )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."CUSTOMER_SALES_SUMMARY"
ALTER TABLE "BIGDATA"."CUSTOMER_SALES_SUMMARY"
	ADD CONSTRAINT "SUMMARY_PK" PRIMARY KEY
		("CUSTNO")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "BIGDATA"."ORDERS"
------------------------------------------------
CREATE TABLE "BIGDATA"."ORDERS" (
		  "ORDER_ID" INTEGER NOT NULL IDENTITY(+5000, +1) ORDER,
		  "ORDER_NO" CHAR(8) NOT NULL,
		  "CUSTNO" CHAR(6) NOT NULL,
		  "ORDER_DATE" DATE NOT NULL,
		  "REQUIRED_DATE" DATE NOT NULL,
		  "SHIPPED_DATE" DATE,
		  "STATUS" VARCHAR(15) NOT NULL DEFAULT 'PENDING',
		  "SUBTOTAL" DECIMAL(11,2) NOT NULL DEFAULT 0.00,
		  "TAX_AMOUNT" DECIMAL(9,2) NOT NULL DEFAULT 0.00,
		  "FREIGHT_CHARGE" DECIMAL(9,2) NOT NULL DEFAULT 0.00,
		  "TOTAL_AMOUNT" DECIMAL(11,2) NOT NULL DEFAULT 0.00,
		  "PAYMENT_METHOD" VARCHAR(20) NOT NULL DEFAULT 'CREDIT',
		  "PAYMENT_STATUS" VARCHAR(15) NOT NULL DEFAULT 'UNPAID',
		  "CREATED_TS" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
		  "UPDATED_TS" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."ORDERS"
ALTER TABLE "BIGDATA"."ORDERS"
	ADD CONSTRAINT "ORDERS_PK" PRIMARY KEY
		("ORDER_ID")
	ENFORCED;


-- DDL Statements for Unique Constraints on Table "BIGDATA"."ORDERS"
ALTER TABLE "BIGDATA"."ORDERS"
	ADD CONSTRAINT "ORDERS_NO_UQ" UNIQUE
		("ORDER_NO")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "BIGDATA"."ORDER_ITEMS"
------------------------------------------------
CREATE TABLE "BIGDATA"."ORDER_ITEMS" (
		  "ITEM_ID" INTEGER NOT NULL IDENTITY(+10000, +1) ORDER,
		  "ORDER_ID" INTEGER NOT NULL,
		  "LINE_NO" SMALLINT NOT NULL,
		  "PRODUCT_ID" INTEGER NOT NULL,
		  "QUANTITY" INTEGER NOT NULL,
		  "UNIT_PRICE" DECIMAL(9,2) NOT NULL,
		  "DISCOUNT_PCT" DECIMAL(5,2) NOT NULL DEFAULT 0.00,
		  "EXTENDED_PRICE" DECIMAL(11,2) NOT NULL )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."ORDER_ITEMS"
ALTER TABLE "BIGDATA"."ORDER_ITEMS"
	ADD CONSTRAINT "ORDER_ITEMS_PK" PRIMARY KEY
		("ITEM_ID")
	ENFORCED;


-- DDL Statements for Unique Constraints on Table "BIGDATA"."ORDER_ITEMS"
ALTER TABLE "BIGDATA"."ORDER_ITEMS"
	ADD CONSTRAINT "ORDER_ITEMS_UQ" UNIQUE
		("ORDER_ID",
		 "LINE_NO")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "BIGDATA"."INVENTORY"
------------------------------------------------
CREATE TABLE "BIGDATA"."INVENTORY" (
		  "WAREHOUSE_ID" CHAR(4) NOT NULL,
		  "PRODUCT_ID" INTEGER NOT NULL,
		  "ON_HAND_QTY" INTEGER NOT NULL DEFAULT 0,
		  "ALLOCATED_QTY" INTEGER NOT NULL DEFAULT 0,
		  "REORDER_POINT" INTEGER NOT NULL DEFAULT 10,
		  "REORDER_QTY" INTEGER NOT NULL DEFAULT 50,
		  "SAFETY_STOCK" INTEGER NOT NULL DEFAULT 5,
		  "BIN_LOCATION" VARCHAR(20) NOT NULL,
		  "LAST_RESTOCK_DATE" DATE,
		  "LAST_AUDIT_TS" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."INVENTORY"
ALTER TABLE "BIGDATA"."INVENTORY"
	ADD CONSTRAINT "INVENTORY_PK" PRIMARY KEY
		("WAREHOUSE_ID",
		 "PRODUCT_ID")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "BIGDATA"."INVENTORY_TRANSACTIONS"
------------------------------------------------
CREATE TABLE "BIGDATA"."INVENTORY_TRANSACTIONS" (
		  "TXN_ID" INTEGER NOT NULL IDENTITY(+1, +1) ORDER,
		  "TXN_TS" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
		  "PRODUCT_ID" INTEGER NOT NULL,
		  "WAREHOUSE_ID" CHAR(4) NOT NULL,
		  "TXN_TYPE" VARCHAR(15) NOT NULL,
		  "QUANTITY" INTEGER NOT NULL,
		  "REFERENCE_NO" VARCHAR(30),
		  "OPERATOR_ID" VARCHAR(20) NOT NULL DEFAULT 'SYSTEM',
		  "NOTES" VARCHAR(255) )
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 IN "USERSPACE1"
----** SSC-FDM-0027 - REMOVED NEXT STATEMENT, NOT APPLICABLE IN SNOWFLAKE.  **
--		 ORGANIZE BY ROW
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}';


-- DDL Statements for Primary Key on Table "BIGDATA"."INVENTORY_TRANSACTIONS"
ALTER TABLE "BIGDATA"."INVENTORY_TRANSACTIONS"
	ADD CONSTRAINT "INV_TXN_PK" PRIMARY KEY
		("TXN_ID")
	ENFORCED;



-- DDL Statements for Foreign Keys on Table "BIGDATA"."INVOICES"
ALTER TABLE "BIGDATA"."INVOICES"
	ADD CONSTRAINT "INV_CUST_FK" FOREIGN KEY
		("INVCUST")
	REFERENCES "BIGDATA"."CUSTOMERS"
		("CUSTNO")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED;
ALTER TABLE "BIGDATA"."INVOICES"
	ADD CONSTRAINT "INV_PROM_FK" FOREIGN KEY
		("INVPROM")
	REFERENCES "BIGDATA"."PROMOTIONS"
		("PROMO_CODE")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED;

-- DDL Statements for Check Constraints on Table "BIGDATA"."PROMOTIONS"
ALTER TABLE "BIGDATA"."PROMOTIONS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "PROMO_PCT_CK" CHECK
		(DISCOUNT_PCT BETWEEN 0 AND 100)
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Check Constraints on Table "BIGDATA"."PRODUCTS"
ALTER TABLE "BIGDATA"."PRODUCTS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "PRODUCTS_ACTIVE_CK" CHECK
		(ACTIVE_FLAG IN ('Y', 'N'))
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Check Constraints on Table "BIGDATA"."PRODUCTS"
ALTER TABLE "BIGDATA"."PRODUCTS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "PRODUCTS_PRICE_CK" CHECK
		(LIST_PRICE >= 0)
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "BIGDATA"."INVOICE_LINES"
ALTER TABLE "BIGDATA"."INVOICE_LINES"
	ADD CONSTRAINT "LINES_INV_FK" FOREIGN KEY
		("INVNO")
	REFERENCES "BIGDATA"."INVOICES"
		("INVNO")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED;
ALTER TABLE "BIGDATA"."INVOICE_LINES"
	ADD CONSTRAINT "LINES_PROD_FK" FOREIGN KEY
		("PRODUCT_ID")
	REFERENCES "BIGDATA"."PRODUCTS"
		("PRODUCT_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED;

-- DDL Statements for Check Constraints on Table "BIGDATA"."INVOICE_LINES"
ALTER TABLE "BIGDATA"."INVOICE_LINES"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "LINES_QTY_CK" CHECK
		(QUANTITY > 0)
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "BIGDATA"."ORDERS"
ALTER TABLE "BIGDATA"."ORDERS"
	ADD CONSTRAINT "ORDERS_CUST_FK" FOREIGN KEY
		("CUSTNO")
	REFERENCES "BIGDATA"."CUSTOMERS"
		("CUSTNO")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED;

-- DDL Statements for Check Constraints on Table "BIGDATA"."ORDERS"
ALTER TABLE "BIGDATA"."ORDERS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "ORDERS_PAY_STATUS_CK" CHECK
		(PAYMENT_STATUS IN ('UNPAID', 'AUTHORIZED', 'PAID', 'REFUNDED'))
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Check Constraints on Table "BIGDATA"."ORDERS"
ALTER TABLE "BIGDATA"."ORDERS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "ORDERS_STATUS_CK" CHECK
		(STATUS IN ('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED',
'ON_HOLD'))
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "BIGDATA"."ORDER_ITEMS"
ALTER TABLE "BIGDATA"."ORDER_ITEMS"
	ADD CONSTRAINT "ITEMS_ORDER_FK" FOREIGN KEY
		("ORDER_ID")
	REFERENCES "BIGDATA"."ORDERS"
		("ORDER_ID")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED;
ALTER TABLE "BIGDATA"."ORDER_ITEMS"
	ADD CONSTRAINT "ITEMS_PROD_FK" FOREIGN KEY
		("PRODUCT_ID")
	REFERENCES "BIGDATA"."PRODUCTS"
		("PRODUCT_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED;

-- DDL Statements for Check Constraints on Table "BIGDATA"."ORDER_ITEMS"
ALTER TABLE "BIGDATA"."ORDER_ITEMS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "ORDER_ITEMS_DISC_CK" CHECK
		(DISCOUNT_PCT BETWEEN 0.00 AND 100.00)
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Check Constraints on Table "BIGDATA"."ORDER_ITEMS"
ALTER TABLE "BIGDATA"."ORDER_ITEMS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "ORDER_ITEMS_QTY_CK" CHECK
		(QUANTITY > 0)
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "BIGDATA"."INVENTORY"
ALTER TABLE "BIGDATA"."INVENTORY"
	ADD CONSTRAINT "INV_PROD_FK" FOREIGN KEY
		("PRODUCT_ID")
	REFERENCES "BIGDATA"."PRODUCTS"
		("PRODUCT_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED;

-- DDL Statements for Check Constraints on Table "BIGDATA"."INVENTORY"
ALTER TABLE "BIGDATA"."INVENTORY"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "INV_ALLOC_CK" CHECK
		(ALLOCATED_QTY >= 0)
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Check Constraints on Table "BIGDATA"."INVENTORY"
ALTER TABLE "BIGDATA"."INVENTORY"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "INV_ON_HAND_CK" CHECK
		(ON_HAND_QTY >= 0)
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "BIGDATA"."INVENTORY_TRANSACTIONS"
ALTER TABLE "BIGDATA"."INVENTORY_TRANSACTIONS"
	ADD CONSTRAINT "TXN_PROD_FK" FOREIGN KEY
		("PRODUCT_ID")
	REFERENCES "BIGDATA"."PRODUCTS"
		("PRODUCT_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED;

-- DDL Statements for Check Constraints on Table "BIGDATA"."INVENTORY_TRANSACTIONS"
ALTER TABLE "BIGDATA"."INVENTORY_TRANSACTIONS"
	ADD
 	   !!!RESOLVE EWI!!! /*** SSC-EWI-0035 - CHECK STATEMENT NOT SUPPORTED ***/!!! CONSTRAINT "INV_TXN_TYPE_CK" CHECK
		(TXN_TYPE IN ('RECEIPT', 'SHIPMENT', 'ALLOCATION', 'DEALLOCATION', 'ADJUSTMENT',
'RETURN'))
	ENFORCED
	ENABLE QUERY OPTIMIZATION;






---------------------------------
-- DDL Statements for User Defined Functions
---------------------------------
CREATE FUNCTION FN_INVOICE_TOTAL (P_SUBT DECIMAL(9,2), P_SHIP DECIMAL(7,2),
P_TAX DECIMAL(7,2))
	 RETURNS DECIMAL(9,2)
	 LANGUAGE SQL
IMMUTABLE
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
$$
	P_SUBT + P_SHIP + P_TAX
$$;
CREATE FUNCTION FN_FORMAT_INVNO (P_NUM INTEGER)
	 RETURNS CHAR(6)
	 LANGUAGE SQL
IMMUTABLE
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
$$
  RIGHT(LPAD(TO_VARCHAR(ABS(P_NUM)), 10, '0'), 6)
$$;
CREATE FUNCTION FN_CUSTOMER_FULLNAME (P_FNAME VARCHAR(20), P_LNAME VARCHAR(30))
	 RETURNS VARCHAR(51)
	 LANGUAGE SQL
IMMUTABLE
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
$$
	RTRIM(P_FNAME) || ' ' || RTRIM(P_LNAME)
$$;


----------------------------

-- DDL Statements for Views

----------------------------
CREATE VIEW V_CUSTOMER_INVOICES
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT C.CUSTNO,
	RTRIM(C.FNAME) || ' ' || RTRIM(C.LNAME) AS CUSTOMER_NAME,
	      C.STATE,
	      I.INVNO,
	      I.INVDATE,
	      I.INVTOTAL,
	      I.INVPROM
FROM
	CUSTOMERS C
	    INNER JOIN
		INVOICES I
	    ON I.INVCUST = C.CUSTNO;
CREATE VIEW V_INVOICE_DETAIL
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT I.INVNO,
	      I.INVDATE,
	      I.INVCUST,
	      L.LINE_NO,
	      P.SKU,
	      P.PRODUCT_NAME,
	      L.QUANTITY,
	      L.UNIT_PRICE,
	      L.LINE_TOTAL
FROM
	INVOICES I
	    INNER JOIN
		INVOICE_LINES L ON L.INVNO = I.INVNO
	    INNER JOIN
		PRODUCTS P ON P.PRODUCT_ID = L.PRODUCT_ID;
CREATE VIEW V_MONTHLY_SALES
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT
	YEAR(INVDATE) AS SALES_YEAR,
	MONTH(INVDATE) AS SALES_MONTH,
	COUNT(*) AS INVOICE_COUNT,
	SUM(INVTOTAL) AS TOTAL_SALES,
	AVG(INVTOTAL) AS AVG_INVOICE
FROM
	INVOICES
GROUP BY YEAR(INVDATE), MONTH(INVDATE);
CREATE VIEW V_PRODUCT_SALES
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT P.SKU,
	      P.PRODUCT_NAME,
	      P.CATEGORY,
	COALESCE(SUM(L.QUANTITY), 0) AS UNITS_SOLD,
	COALESCE(SUM(L.LINE_TOTAL), 0) AS REVENUE
FROM
	PRODUCTS P
	    LEFT OUTER JOIN
		INVOICE_LINES L
	    ON L.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.SKU, P.PRODUCT_NAME, P.CATEGORY;
CREATE VIEW V_PROMO_USAGE
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT R.PROMO_CODE,
	      R.PROMO_NAME,
	      R.DISCOUNT_PCT,
	COUNT(I.INVNO) AS INVOICES_USED,
	COALESCE(SUM(I.INVTOTAL), 0) AS SALES_WITH_PROMO
FROM
	PROMOTIONS R
	    LEFT OUTER JOIN
		INVOICES I
	    ON I.INVPROM = R.PROMO_CODE
GROUP BY R.PROMO_CODE, R.PROMO_NAME, R.DISCOUNT_PCT;
CREATE VIEW V_ORDER_FULFILLMENT_STATUS
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT O.ORDER_ID,
	      O.ORDER_NO,
	      O.CUSTNO,
	RTRIM(C.FNAME) || ' ' || RTRIM(C.LNAME) AS CUSTOMER_NAME,
	      C.STATE,
	      O.ORDER_DATE,
	      O.REQUIRED_DATE,
	      O.SHIPPED_DATE,
	      CASE
          WHEN O.SHIPPED_DATE IS NOT NULL THEN DATEDIFF(day, O.ORDER_DATE, O.SHIPPED_DATE)
	        ELSE NULL
	      END AS FULFILLMENT_DAYS,
	      O.STATUS,
	      O.TOTAL_AMOUNT,
	COUNT(OI.ITEM_ID) AS ITEM_COUNT,
	COALESCE(SUM(OI.QUANTITY), 0) AS TOTAL_UNITS
FROM
	ORDERS O
	    INNER JOIN
	        CUSTOMERS C ON C.CUSTNO = O.CUSTNO
	    LEFT OUTER JOIN
	        ORDER_ITEMS OI ON OI.ORDER_ID = O.ORDER_ID
GROUP BY O.ORDER_ID, O.ORDER_NO, O.CUSTNO, C.FNAME, C.LNAME, C.STATE,
	        O.ORDER_DATE, O.REQUIRED_DATE, O.SHIPPED_DATE, O.STATUS, O.TOTAL_AMOUNT;
CREATE VIEW V_INVENTORY_RESTOCK_ALERT
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT I.WAREHOUSE_ID,
	      P.PRODUCT_ID,
	      P.SKU,
	      P.PRODUCT_NAME,
	      I.ON_HAND_QTY,
	      I.ALLOCATED_QTY,
	      (I.ON_HAND_QTY - I.ALLOCATED_QTY) AS AVAILABLE_QTY,
	      I.REORDER_POINT,
	      I.REORDER_QTY,
	      I.SAFETY_STOCK,
	      I.BIN_LOCATION,
	      CASE
	        WHEN (I.ON_HAND_QTY - I.ALLOCATED_QTY) <= I.SAFETY_STOCK THEN 'CRITICAL'
	        WHEN (I.ON_HAND_QTY - I.ALLOCATED_QTY) <= I.REORDER_POINT THEN 'REORDER_NOW'
	        ELSE 'HEALTHY'
	      END AS INVENTORY_STATUS
FROM
	INVENTORY I
	    INNER JOIN
	        PRODUCTS P ON P.PRODUCT_ID = I.PRODUCT_ID
WHERE (I.ON_HAND_QTY - I.ALLOCATED_QTY) <= I.REORDER_POINT;
CREATE VIEW V_CUSTOMER_360_ORDERS
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
SELECT C.CUSTNO,
	RTRIM(C.FNAME) || ' ' || RTRIM(C.LNAME) AS CUSTOMER_NAME,
	      C.CITY,
	      C.STATE,
	COUNT(O.ORDER_ID) AS TOTAL_ORDERS,
	COALESCE(SUM(O.TOTAL_AMOUNT), 0.00) AS LIFETIME_ORDER_VALUE,
	MAX(O.ORDER_DATE) AS LAST_ORDER_DATE,
	SUM(CASE WHEN O.STATUS IN ('PENDING', 'PROCESSING') THEN 1 ELSE 0 END) AS OPEN_ORDERS_COUNT
FROM
	CUSTOMERS C
	    LEFT OUTER JOIN
	        ORDERS O ON O.CUSTNO = C.CUSTNO
GROUP BY C.CUSTNO, C.FNAME, C.LNAME, C.CITY, C.STATE;





---------------------------------
-- DDL Statements for Stored Procedures
---------------------------------
CREATE PROCEDURE SP_ADD_CUSTOMER (
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_CUSTNO  CHAR(6),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_FNAME   VARCHAR(20),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_LNAME   VARCHAR(30),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_ADDR    VARCHAR(30),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_CITY    VARCHAR(20),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_STATE   CHAR(2),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_ZIP     VARCHAR(10),
	 OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_STATUS  INTEGER)
RETURNS VARCHAR
	 LANGUAGE SQL
	 MODIFIES SQL DATA
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
$$
	--
	--
BEGIN
	        P_STATUS := 0; --

	 INSERT INTO CUSTOMERS (CUSTNO, FNAME, LNAME, ADDR, CITY, STATE, ZIPCODE)
	 VALUES (:P_CUSTNO, :P_FNAME, :P_LNAME, :P_ADDR, :P_CITY, :P_STATE, :P_ZIP);--

	 INSERT INTO CUSTOMER_AUDIT (CUSTNO, ACTION_CD, NOTES)
	 VALUES (:P_CUSTNO, 'A', 'Customer added');--

	        EXCEPTION
			WHEN OTHER EXIT THEN
				CASE
					WHEN (SQLSTATE = '23505') THEN
						SET P_STATUS = -1
					ELSE
						SET P_STATUS = -99
				END;
END
$$;
CREATE PROCEDURE SP_CHECK_INVENTORY_SHORTAGE (
	 OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_CRITICAL_ITEMS_COUNT INTEGER,
	 OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_TOTAL_UNITS_DEFICIT  INTEGER
)
RETURNS VARCHAR
LANGUAGE SQL
MODIFIES SQL DATA
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
--
AS
$$
	--
	--
	--
	--
	DECLARE
	        V_ON_HAND      INTEGER;--
	        V_ALLOCATED    INTEGER;--
	        V_REORDER_PT   INTEGER;--
	        V_AVAIL        INTEGER;--
	        V_AT_END       SMALLINT DEFAULT 0;--

	BEGIN
	 DECLARE C_SHORTAGE CURSOR FOR
	   SELECT ON_HAND_QTY, ALLOCATED_QTY, REORDER_POINT
	     FROM
				INVENTORY
	    WHERE (ON_HAND_QTY - ALLOCATED_QTY) < REORDER_POINT;--
	        P_CRITICAL_ITEMS_COUNT := 0; --
	        P_TOTAL_UNITS_DEFICIT := 0; --

	 OPEN C_SHORTAGE;--
	 FETCH C_SHORTAGE INTO V_ON_HAND, V_ALLOCATED, V_REORDER_PT;--

	        WHILE (:V_AT_END = 0) DO
			V_AVAIL := V_ON_HAND - V_ALLOCATED; --
			P_CRITICAL_ITEMS_COUNT := P_CRITICAL_ITEMS_COUNT + 1; --
			P_TOTAL_UNITS_DEFICIT := P_TOTAL_UNITS_DEFICIT + (V_REORDER_PT - V_AVAIL); --

	   FETCH C_SHORTAGE INTO V_ON_HAND, V_ALLOCATED, V_REORDER_PT;--
	 END WHILE;--

	 CLOSE C_SHORTAGE;--

	        EXCEPTION
			WHEN OTHER CONTINUE THEN
				CASE
					WHEN (SQLSTATE = '42S02') THEN
						SET V_AT_END = 1
				END;
	END
$$;--;
CREATE PROCEDURE SP_PLACE_ORDER (
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_CUSTNO         CHAR(6),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_ORDER_NO       CHAR(8),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_PAYMENT_METHOD VARCHAR(20),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_SUBTOTAL       DECIMAL(11,2),
	 OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_ORDER_ID       INTEGER,
	 OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_TOTAL_AMOUNT   DECIMAL(11,2)
)
RETURNS VARCHAR
LANGUAGE SQL
MODIFIES SQL DATA
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
--
AS
$$
	--
	--
	--
	DECLARE
	        V_CUST_EXISTS INTEGER DEFAULT 0;--
	        V_TAX         DECIMAL(9,2) DEFAULT 0.00;--
	        V_FREIGHT     DECIMAL(9,2) DEFAULT 15.00;--
	        V_STATE       CHAR(2);--

	BEGIN
	 DECLARE CUST_MISSING  CONDITION FOR SQLSTATE '75002' !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'ConditionDeclaration' NODE ***/!!!;--

	 SELECT STATE INTO
			:V_STATE
	   FROM
			CUSTOMERS
	  WHERE CUSTNO = :P_CUSTNO;--

	        -- Apply 6% tax for TX, 7% for CA/NY
	        IF (:V_STATE = 'TX') THEN
			V_TAX := ROUND(P_SUBTOTAL * 0.06, 2); --
	        ELSEIF ( V_STATE IN ('CA', 'NY')) THEN
			V_TAX := ROUND(P_SUBTOTAL * 0.07, 2); --
	        ELSE
			V_TAX := 0.00; --

	        END IF;--
	        P_TOTAL_AMOUNT := P_SUBTOTAL + V_TAX + V_FREIGHT; --

	 INSERT INTO ORDERS (
	   ORDER_NO,
	   CUSTNO,
	   ORDER_DATE,
	   REQUIRED_DATE,
	   STATUS,
	   SUBTOTAL,
	   TAX_AMOUNT,
	   FREIGHT_CHARGE,
	   TOTAL_AMOUNT,
	   PAYMENT_METHOD,
	   PAYMENT_STATUS
	 ) VALUES (:P_ORDER_NO, :P_CUSTNO, CURRENT_DATE(), CURRENT_DATE() + 7 DAYS,
	   'PENDING', :P_SUBTOTAL, :V_TAX, :V_FREIGHT, :P_TOTAL_AMOUNT, :P_PAYMENT_METHOD,
	   'AUTHORIZED'
	 );--

	 SELECT ORDER_ID INTO
			:P_ORDER_ID
	   FROM
			ORDERS
	  WHERE ORDER_NO = :P_ORDER_NO;--

	        EXCEPTION
			WHEN OTHER EXIT THEN
				CASE
					WHEN (SQLSTATE = '42S02') THEN
						SIGNAL CUST_MISSING SET MESSAGE_TEXT = 'Customer does not exist in CUSTOMERS table' !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'Signal' NODE ***/!!!
				END;
	END
$$;--
;
CREATE PROCEDURE SP_REFRESH_CUSTOMER_SUMMARY (OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_ROWS INTEGER)
RETURNS VARCHAR
	 LANGUAGE SQL
	 MODIFIES SQL DATA
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
--
AS
$$
	--
	--
	--
	--
	DECLARE
	        V_CUSTNO  CHAR(6);--
	        V_COUNT   INTEGER;--
	        V_TOTAL   DECIMAL(11,2);--
	        V_LAST    DATE;--
	        V_AT_END  SMALLINT DEFAULT 0;--

	BEGIN
	 DECLARE C1 CURSOR FOR
	   SELECT INVCUST,
				COUNT(*),
				SUM(INVTOTAL),
				MAX(INVDATE)
	     FROM
				INVOICES
	    GROUP BY INVCUST
	    ORDER BY INVCUST;--
	        P_ROWS := 0; --

	 DELETE FROM
			CUSTOMER_SALES_SUMMARY;--

	 OPEN C1;--
	 FETCH C1 INTO V_CUSTNO, V_COUNT, V_TOTAL, V_LAST;--

	        WHILE (:V_AT_END = 0) DO
	   INSERT INTO CUSTOMER_SALES_SUMMARY
	          (CUSTNO, INVOICE_COUNT, TOTAL_SALES, LAST_INVOICE_DATE, REFRESHED_TS)
	   VALUES (:V_CUSTNO, :V_COUNT, :V_TOTAL, :V_LAST, CURRENT_TIMESTAMP());--
			P_ROWS := P_ROWS + 1; --
	   FETCH C1 INTO V_CUSTNO, V_COUNT, V_TOTAL, V_LAST;--
	 END WHILE;--

	 CLOSE C1;--

	        EXCEPTION
			WHEN OTHER CONTINUE THEN
				CASE
					WHEN (SQLSTATE = '42S02') THEN
						SET V_AT_END = 1
				END;
	END
$$;--;
CREATE PROCEDURE SP_RESTOCK_INVENTORY (
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_WAREHOUSE_ID   CHAR(4),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_PRODUCT_ID     INTEGER,
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_RESTOCK_QTY    INTEGER,
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_OPERATOR_ID    VARCHAR(20),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_PO_NUMBER      VARCHAR(30),
	 OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_NEW_ON_HAND    INTEGER
)
RETURNS VARCHAR
LANGUAGE SQL
MODIFIES SQL DATA
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
--
AS
$$
	DECLARE
	        V_CURRENT_QTY INTEGER;--

	BEGIN
	 DECLARE INV_NOT_FOUND CONDITION FOR SQLSTATE '75003' !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'ConditionDeclaration' NODE ***/!!!;--

	 SELECT ON_HAND_QTY INTO
			:V_CURRENT_QTY
	   FROM
			INVENTORY
	  WHERE WAREHOUSE_ID = :P_WAREHOUSE_ID
	    AND PRODUCT_ID = :P_PRODUCT_ID;--
	        P_NEW_ON_HAND := V_CURRENT_QTY + P_RESTOCK_QTY; --

	 UPDATE INVENTORY
	    SET ON_HAND_QTY = :P_NEW_ON_HAND,
	        LAST_RESTOCK_DATE = CURRENT_DATE(),
	        LAST_AUDIT_TS = CURRENT_TIMESTAMP()
	  WHERE WAREHOUSE_ID = :P_WAREHOUSE_ID
	    AND PRODUCT_ID = :P_PRODUCT_ID;--

	 INSERT INTO INVENTORY_TRANSACTIONS (
	   PRODUCT_ID,
	   WAREHOUSE_ID,
	   TXN_TYPE,
	   QUANTITY,
	   REFERENCE_NO,
	   OPERATOR_ID,
	   NOTES
	 ) VALUES (:P_PRODUCT_ID, :P_WAREHOUSE_ID,
	   'RECEIPT', :P_RESTOCK_QTY, :P_PO_NUMBER, :P_OPERATOR_ID,
	   'Restock replenishment processed successfully'
	 );--

	        EXCEPTION
			WHEN OTHER EXIT THEN
				CASE
					WHEN (SQLSTATE = '42S02') THEN
						SIGNAL INV_NOT_FOUND SET MESSAGE_TEXT = 'Warehouse product inventory record not found' !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'Signal' NODE ***/!!!
				END;
	END
$$;--;
CREATE PROCEDURE SP_UPDATE_CUSTOMER_ADDRESS (
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_CUSTNO  CHAR(6),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_ADDR    VARCHAR(30),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_CITY    VARCHAR(20),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_STATE   CHAR(2),
	 IN !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'InParameterMode' NODE ***/!!!  P_ZIP     VARCHAR(10),
	 OUT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'OutParameterMode' NODE ***/!!! P_ROWS    INTEGER)
RETURNS VARCHAR
	 LANGUAGE SQL
	 MODIFIES SQL DATA
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 51,  "patch": "1-Pr" }, "attributes": {  "component": "db2",  "convertedOn": "11/11/2026",  "domain": "no-domain-provided",  "migrationid": "+8mhARM3jnqjj/PQbquepw==" }}'
AS
$$
	DECLARE
	        V_ROWS INTEGER DEFAULT 0;--

	BEGIN
	 UPDATE CUSTOMERS
	    SET ADDR    = :P_ADDR,
	        CITY    = :P_CITY,
	        STATE   = :P_STATE,
	        ZIPCODE = :P_ZIP
	  WHERE CUSTNO = :P_CUSTNO;--

	 GET DIAGNOSTICS V_ROWS = ROW_COUNT !!!RESOLVE EWI!!! /*** SSC-EWI-0073 - PENDING FUNCTIONAL EQUIVALENCE REVIEW FOR 'StatementInformation' NODE ***/!!!;--

	        IF (:V_ROWS > 0) THEN
			INSERT INTO CUSTOMER_AUDIT (CUSTNO, ACTION_CD, NOTES)
			VALUES (:P_CUSTNO, 'U', 'Address changed');--

	        END IF;--
	        P_ROWS := V_ROWS; --

	END
$$;--;

-- [migration] removed db2look session footer: COMMIT WORK / CONNECT RESET / TERMINATE