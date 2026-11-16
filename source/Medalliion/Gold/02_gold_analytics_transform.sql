-- ============================================================================
-- GOLD LAYER ADVANCED ANALYTICAL TRANSFORMATIONS - IBM DB2 LUW LEGACY
-- ============================================================================
-- Purpose: Executes heavy, multi-stage enterprise reporting transformations.
-- Features advanced DB2 LUW analytical constructs:
--   - Multi-level Common Table Expressions (CTEs: WITH ... AS)
--   - Cumulative window running totals (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--   - Moving rolling averages (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
--   - Period-over-period delta calculations with LAG() OVER (...)
--   - Analytical ranking & quintiles (DENSE_RANK, PERCENT_RANK, NTILE(5))
--   - RFM (Recency, Frequency, Monetary) customer value scoring
--   - Inventory turnover and daily burn-rate velocity calculations
--   - DB2 date functions: DAYS(), YEAR(), MONTH()
--   - Query isolation and optimization: OPTIMIZE FOR 100 ROWS, WITH UR
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: POPULATE GOLD MONTHLY SALES PERFORMANCE REPORTING MART
-- Computes order counts, fulfillment SLA %, revenue breakdowns, rolling YTD totals,
-- and Month-over-Month (MoM) growth percentages using LAG() analytical windowing.
-- ----------------------------------------------------------------------------
INSERT INTO GOLD_FACT_SALES_PERFORMANCE_MONTHLY (
    CALENDAR_YEAR,
    CALENDAR_MONTH,
    REGION,
    PAYMENT_METHOD,
    TOTAL_ORDERS,
    COMPLETED_ORDERS,
    CANCELLED_ORDERS,
    LATE_DELIVERIES,
    ON_TIME_DELIVERY_PCT,
    TOTAL_UNITS_SOLD,
    GROSS_SUBTOTAL,
    TOTAL_TAX,
    TOTAL_FREIGHT,
    NET_REVENUE,
    AVG_ORDER_VALUE,
    AVG_FULFILLMENT_DAYS,
    RUNNING_YTD_REVENUE,
    MOM_GROWTH_PCT,
    MART_REFRESHED_TS
)
WITH CTE_ORDER_GRAIN AS (
    -- Grain: Monthly by Region and Payment Method
    SELECT 
        YEAR(FO.ORDER_DATE)                                       AS CAL_YEAR,
        MONTH(FO.ORDER_DATE)                                      AS CAL_MONTH,
        DC.REGION                                                 AS SALES_REGION,
        FO.PAYMENT_METHOD                                         AS PAY_METHOD,
        COUNT(FO.ORDER_KEY)                                       AS TOT_ORDERS,
        SUM(CASE WHEN FO.ORDER_STATUS = 'DELIVERED' THEN 1 ELSE 0 END) AS COMP_ORDERS,
        SUM(CASE WHEN FO.ORDER_STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANC_ORDERS,
        SUM(CASE WHEN FO.IS_LATE_FLAG = 'Y' THEN 1 ELSE 0 END)    AS LATE_ORDS,
        SUM(FO.TOTAL_UNITS)                                       AS TOT_UNITS,
        SUM(FO.SUBTOTAL)                                          AS GROSS_SUBT,
        SUM(FO.TAX_AMOUNT)                                        AS TOT_TAX,
        SUM(FO.FREIGHT_CHARGE)                                    AS TOT_FREIGHT,
        SUM(FO.TOTAL_AMOUNT)                                      AS NET_REV,
        AVG(FO.TOTAL_AMOUNT)                                      AS AOV,
        AVG(CASE WHEN FO.DAYS_TO_FULFILL IS NOT NULL THEN FO.DAYS_TO_FULFILL ELSE NULL END) AS AVG_FULFILL
    FROM SILVER_FACT_ORDERS FO
    INNER JOIN SILVER_DIM_CUSTOMER DC 
        ON DC.CUSTOMER_KEY = FO.CUSTOMER_KEY
    GROUP BY 
        YEAR(FO.ORDER_DATE),
        MONTH(FO.ORDER_DATE),
        DC.REGION,
        FO.PAYMENT_METHOD
),
CTE_WINDOWED_METRICS AS (
    -- Analytical windowing: Cumulative YTD revenue & previous month revenue for MoM%
    SELECT 
        G.CAL_YEAR,
        G.CAL_MONTH,
        G.SALES_REGION,
        G.PAY_METHOD,
        G.TOT_ORDERS,
        G.COMP_ORDERS,
        G.CANC_ORDERS,
        G.LATE_ORDS,
        CASE 
            WHEN G.TOT_ORDERS > 0 
                 THEN ROUND((DECIMAL(G.TOT_ORDERS - G.LATE_ORDS, 9, 2) / DECIMAL(G.TOT_ORDERS, 9, 2)) * 100.00, 2)
            ELSE 100.00 
        END AS ON_TIME_PCT,
        G.TOT_UNITS,
        G.GROSS_SUBT,
        G.TOT_TAX,
        G.TOT_FREIGHT,
        G.NET_REV,
        ROUND(G.AOV, 2) AS AVG_ORDER_VAL,
        ROUND(G.AVG_FULFILL, 2) AS AVG_FULFILL_DAYS,
        -- Running cumulative YTD sum partitioned by Year and Region
        SUM(G.NET_REV) OVER (
            PARTITION BY G.CAL_YEAR, G.SALES_REGION 
            ORDER BY G.CAL_MONTH 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RUNNING_YTD,
        -- Lagged previous month revenue to calculate MoM growth
        LAG(G.NET_REV, 1) OVER (
            PARTITION BY G.CAL_YEAR, G.SALES_REGION, G.PAY_METHOD 
            ORDER BY G.CAL_MONTH
        ) AS PREV_MONTH_REV
    FROM CTE_ORDER_GRAIN G
)
SELECT 
    W.CAL_YEAR                                                    AS CALENDAR_YEAR,
    W.CAL_MONTH                                                   AS CALENDAR_MONTH,
    W.SALES_REGION                                                AS REGION,
    W.PAY_METHOD                                                  AS PAYMENT_METHOD,
    W.TOT_ORDERS                                                  AS TOTAL_ORDERS,
    W.COMP_ORDERS                                                 AS COMPLETED_ORDERS,
    W.CANC_ORDERS                                                 AS CANCELLED_ORDERS,
    W.LATE_ORDS                                                   AS LATE_DELIVERIES,
    W.ON_TIME_PCT                                                 AS ON_TIME_DELIVERY_PCT,
    W.TOT_UNITS                                                   AS TOTAL_UNITS_SOLD,
    W.GROSS_SUBT                                                  AS GROSS_SUBTOTAL,
    W.TOT_TAX                                                     AS TOTAL_TAX,
    W.TOT_FREIGHT                                                 AS TOTAL_FREIGHT,
    W.NET_REV                                                     AS NET_REVENUE,
    W.AVG_ORDER_VAL                                               AS AVG_ORDER_VALUE,
    W.AVG_FULFILL_DAYS                                            AS AVG_FULFILLMENT_DAYS,
    W.RUNNING_YTD                                                 AS RUNNING_YTD_REVENUE,
    CASE 
        WHEN W.PREV_MONTH_REV IS NOT NULL AND W.PREV_MONTH_REV > 0 
             THEN ROUND(((W.NET_REV - W.PREV_MONTH_REV) / W.PREV_MONTH_REV) * 100.00, 2)
        ELSE NULL 
    END                                                           AS MOM_GROWTH_PCT,
    CURRENT TIMESTAMP                                             AS MART_REFRESHED_TS
FROM CTE_WINDOWED_METRICS W
OPTIMIZE FOR 100 ROWS
WITH UR;

-- ----------------------------------------------------------------------------
-- STEP 2: POPULATE GOLD CUSTOMER RFM SEGMENTATION MART
-- Implements Recency, Frequency, Monetary scoring via NTILE(5) quintile window functions.
-- Classifies customers into behavioral segments (CHAMPIONS, LOYAL, AT RISK, HIBERNATING).
-- ----------------------------------------------------------------------------
INSERT INTO GOLD_DIM_CUSTOMER_RFM_METRICS (
    CUSTOMER_KEY,
    CUSTNO,
    CUSTOMER_NAME,
    REGION,
    FIRST_ORDER_DATE,
    LAST_ORDER_DATE,
    DAYS_SINCE_LAST_ORD,
    LIFETIME_ORDER_COUNT,
    LIFETIME_SPEND,
    RECENCY_SCORE,
    FREQUENCY_SCORE,
    MONETARY_SCORE,
    RFM_COMPOSITE_SCORE,
    CUSTOMER_SEGMENT,
    SPEND_RANK,
    SPEND_PERCENTILE,
    MART_REFRESHED_TS
)
WITH CTE_CUSTOMER_METRICS AS (
    SELECT 
        C.CUSTOMER_KEY,
        C.CUSTNO,
        C.FULL_NAME,
        C.REGION,
        MIN(O.ORDER_DATE)                                         AS FIRST_ORD_DT,
        MAX(O.ORDER_DATE)                                         AS LAST_ORD_DT,
        DAYS(CURRENT DATE) - DAYS(MAX(O.ORDER_DATE))              AS DAYS_INACTIVE,
        COUNT(O.ORDER_KEY)                                        AS TOTAL_ORDERS,
        SUM(O.TOTAL_AMOUNT)                                       AS TOTAL_SPEND
    FROM SILVER_DIM_CUSTOMER C
    INNER JOIN SILVER_FACT_ORDERS O 
        ON O.CUSTOMER_KEY = C.CUSTOMER_KEY
    WHERE C.IS_CURRENT = 'Y'
    GROUP BY C.CUSTOMER_KEY, C.CUSTNO, C.FULL_NAME, C.REGION
),
CTE_RFM_SCORES AS (
    SELECT 
        M.CUSTOMER_KEY,
        M.CUSTNO,
        M.FULL_NAME,
        M.REGION,
        M.FIRST_ORD_DT,
        M.LAST_ORD_DT,
        M.DAYS_INACTIVE,
        M.TOTAL_ORDERS,
        M.TOTAL_SPEND,
        -- Recency: fewer days inactive gets higher score (5 = most recent)
        6 - NTILE(5) OVER (ORDER BY M.DAYS_INACTIVE ASC)          AS R_SCORE,
        -- Frequency: more orders gets higher score (5 = most frequent)
        NTILE(5) OVER (ORDER BY M.TOTAL_ORDERS ASC)               AS F_SCORE,
        -- Monetary: higher spend gets higher score (5 = highest spender)
        NTILE(5) OVER (ORDER BY M.TOTAL_SPEND ASC)                AS M_SCORE,
        -- Spending ranks across the customer base
        DENSE_RANK() OVER (ORDER BY M.TOTAL_SPEND DESC)           AS S_RANK,
        PERCENT_RANK() OVER (ORDER BY M.TOTAL_SPEND ASC)          AS S_PCT
    FROM CTE_CUSTOMER_METRICS M
)
SELECT 
    S.CUSTOMER_KEY,
    S.CUSTNO,
    S.FULL_NAME                                                   AS CUSTOMER_NAME,
    S.REGION,
    S.FIRST_ORD_DT                                                AS FIRST_ORDER_DATE,
    S.LAST_ORD_DT                                                 AS LAST_ORDER_DATE,
    S.DAYS_INACTIVE                                               AS DAYS_SINCE_LAST_ORD,
    S.TOTAL_ORDERS                                                AS LIFETIME_ORDER_COUNT,
    S.TOTAL_SPEND                                                 AS LIFETIME_SPEND,
    SMALLINT(S.R_SCORE)                                           AS RECENCY_SCORE,
    SMALLINT(S.F_SCORE)                                           AS FREQUENCY_SCORE,
    SMALLINT(S.M_SCORE)                                           AS MONETARY_SCORE,
    CHAR(S.R_SCORE) || CHAR(S.F_SCORE) || CHAR(S.M_SCORE)         AS RFM_COMPOSITE_SCORE,
    CASE 
        WHEN S.R_SCORE >= 4 AND S.F_SCORE >= 4 AND S.M_SCORE >= 4 THEN 'CHAMPIONS'
        WHEN S.R_SCORE >= 3 AND S.F_SCORE >= 3 AND S.M_SCORE >= 3 THEN 'LOYAL_CUSTOMERS'
        WHEN S.R_SCORE >= 4 AND S.F_SCORE <= 2                    THEN 'NEW_POTENTIAL'
        WHEN S.R_SCORE <= 2 AND S.F_SCORE >= 3                    THEN 'AT_RISK_HIGH_VALUE'
        WHEN S.R_SCORE <= 2 AND S.F_SCORE <= 2                    THEN 'HIBERNATING_LOST'
        ELSE 'AVERAGE_ENGAGEMENT'
    END                                                           AS CUSTOMER_SEGMENT,
    S.S_RANK                                                      AS SPEND_RANK,
    DECIMAL(S.S_PCT, 5, 4)                                        AS SPEND_PERCENTILE,
    CURRENT TIMESTAMP                                             AS MART_REFRESHED_TS
FROM CTE_RFM_SCORES S
OPTIMIZE FOR 100 ROWS
WITH UR;

-- ----------------------------------------------------------------------------
-- STEP 3: POPULATE GOLD INVENTORY VELOCITY MART
-- Computes SKU burn rates over last 30 days, projects days of stock remaining,
-- calculates turnover ratios, and assigns replenishment priority tiers.
-- ----------------------------------------------------------------------------
INSERT INTO GOLD_INVENTORY_VELOCITY_MART (
    WAREHOUSE_ID,
    SKU,
    PRODUCT_NAME,
    CATEGORY,
    CURRENT_ON_HAND,
    CURRENT_AVAILABLE,
    UNITS_SOLD_L30D,
    DAILY_BURN_RATE,
    DAYS_OF_SUPPLY_LEFT,
    TURNOVER_RATIO,
    STOCKOUT_RISK_TIER,
    SUGGESTED_ORDER_QTY,
    MART_REFRESHED_TS
)
WITH CTE_SALES_L30D AS (
    SELECT 
        P.SKU,
        COALESCE(SUM(OI.QUANTITY), 0)                             AS UNITS_SOLD
    FROM PRODUCTS P
    LEFT OUTER JOIN ORDER_ITEMS OI 
        ON OI.PRODUCT_ID = P.PRODUCT_ID
    LEFT OUTER JOIN ORDERS O 
        ON O.ORDER_ID = OI.ORDER_ID
       AND O.ORDER_DATE >= (CURRENT DATE - 30 DAYS)
    GROUP BY P.SKU
)
SELECT 
    I.WAREHOUSE_ID,
    I.SKU,
    DP.PRODUCT_NAME,
    DP.CATEGORY,
    I.ON_HAND_QTY                                                 AS CURRENT_ON_HAND,
    I.AVAILABLE_QTY                                               AS CURRENT_AVAILABLE,
    S.UNITS_SOLD                                                  AS UNITS_SOLD_L30D,
    ROUND(DECIMAL(S.UNITS_SOLD, 9, 2) / 30.00, 2)                 AS DAILY_BURN_RATE,
    CASE 
        WHEN S.UNITS_SOLD > 0 
             THEN INTEGER(DECIMAL(I.AVAILABLE_QTY, 9, 2) / (DECIMAL(S.UNITS_SOLD, 9, 2) / 30.00))
        ELSE 999 
    END                                                           AS DAYS_OF_SUPPLY_LEFT,
    CASE 
        WHEN I.ON_HAND_QTY > 0 
             THEN ROUND((DECIMAL(S.UNITS_SOLD, 9, 2) * 12.00) / DECIMAL(I.ON_HAND_QTY, 9, 2), 2)
        ELSE 0.00 
    END                                                           AS TURNOVER_RATIO,
    CASE 
        WHEN I.AVAILABLE_QTY <= I.SAFETY_STOCK THEN 'TIER_1_CRITICAL'
        WHEN I.AVAILABLE_QTY <= I.REORDER_POINT THEN 'TIER_2_ELEVATED'
        WHEN S.UNITS_SOLD = 0 THEN 'TIER_4_DEAD_STOCK'
        ELSE 'TIER_3_NORMAL'
    END                                                           AS STOCKOUT_RISK_TIER,
    CASE 
        WHEN I.AVAILABLE_QTY <= I.REORDER_POINT 
             THEN (I.REORDER_QTY + (I.REORDER_POINT - I.AVAILABLE_QTY))
        ELSE 0 
    END                                                           AS SUGGESTED_ORDER_QTY,
    CURRENT TIMESTAMP                                             AS MART_REFRESHED_TS
FROM SILVER_FACT_INVENTORY_DAILY I
INNER JOIN SILVER_DIM_PRODUCT DP 
    ON DP.SKU = I.SKU
LEFT OUTER JOIN CTE_SALES_L30D S 
    ON S.SKU = I.SKU
WHERE I.SNAPSHOT_DATE = CURRENT DATE
OPTIMIZE FOR 100 ROWS
WITH UR;

-- ----------------------------------------------------------------------------
-- STEP 4: POPULATE EXECUTIVE C-LEVEL DAILY KPI SNAPSHOT
-- Summarizes overall enterprise health into an executive single-row scorecard.
-- ----------------------------------------------------------------------------
INSERT INTO GOLD_EXECUTIVE_SUMMARY_KPI (
    KPI_SNAPSHOT_DATE,
    MTD_TOTAL_REVENUE,
    YTD_TOTAL_REVENUE,
    ACTIVE_CUSTOMER_CNT,
    TOTAL_OPEN_ORDERS,
    FULFILLMENT_SLA_PCT,
    AVG_BASKET_SIZE,
    CRITICAL_STOCK_SKUS,
    CALCULATED_TS
)
SELECT 
    CURRENT DATE                                                  AS KPI_SNAPSHOT_DATE,
    -- Month-To-Date Revenue
    VALUE((
        SELECT SUM(TOTAL_AMOUNT) 
        FROM SILVER_FACT_ORDERS 
        WHERE YEAR(ORDER_DATE) = YEAR(CURRENT DATE) 
          AND MONTH(ORDER_DATE) = MONTH(CURRENT DATE)
    ), 0.00)                                                      AS MTD_TOTAL_REVENUE,
    -- Year-To-Date Revenue
    VALUE((
        SELECT SUM(TOTAL_AMOUNT) 
        FROM SILVER_FACT_ORDERS 
        WHERE YEAR(ORDER_DATE) = YEAR(CURRENT DATE)
    ), 0.00)                                                      AS YTD_TOTAL_REVENUE,
    -- Active Customers
    VALUE((
        SELECT COUNT(DISTINCT CUSTOMER_KEY) 
        FROM SILVER_FACT_ORDERS 
        WHERE ORDER_DATE >= (CURRENT DATE - 90 DAYS)
    ), 0)                                                         AS ACTIVE_CUSTOMER_CNT,
    -- Total Open Orders
    VALUE((
        SELECT COUNT(*) 
        FROM SILVER_FACT_ORDERS 
        WHERE ORDER_STATUS IN ('PENDING', 'PROCESSING', 'ON_HOLD')
    ), 0)                                                         AS TOTAL_OPEN_ORDERS,
    -- SLA Delivery %
    VALUE((
        SELECT ROUND((DECIMAL(COUNT(CASE WHEN IS_LATE_FLAG = 'N' THEN 1 END), 9, 2) / 
                      DECIMAL(NULLIF(COUNT(*), 0), 9, 2)) * 100.00, 2)
        FROM SILVER_FACT_ORDERS
    ), 100.00)                                                    AS FULFILLMENT_SLA_PCT,
    -- Average Units Per Order
    VALUE((
        SELECT ROUND(AVG(DECIMAL(TOTAL_UNITS, 7, 2)), 2) 
        FROM SILVER_FACT_ORDERS
    ), 0.00)                                                      AS AVG_BASKET_SIZE,
    -- Critical Inventory SKUs
    VALUE((
        SELECT COUNT(DISTINCT SKU) 
        FROM SILVER_FACT_INVENTORY_DAILY 
        WHERE STOCKOUT_RISK_FLAG = 'Y' AND SNAPSHOT_DATE = CURRENT DATE
    ), 0)                                                         AS CRITICAL_STOCK_SKUS,
    CURRENT TIMESTAMP                                             AS CALCULATED_TS
FROM SYSIBM.SYSDUMMY1
WITH UR;
