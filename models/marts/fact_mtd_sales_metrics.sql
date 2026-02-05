-- Model: fact_mtd_sales_metrics
-- Layer: mart
-- Description: Standardized MTD sales, fulfillment and PO value metrics with multi-GRN channel handling
-- Grain: sku_id, location_id, channel_name, month_start
-- Downstream use: AWS QuickSight dashboards


-- Challenge:
-- Marketplace channels such as Flipkart/Myntra/Amazon vendors often follow multi-GRN workflows where shipments
-- are received in parts. In such cases, order quantity may not reflect the actual committed demand for the month.
-- If standard fill rate logic is applied, it inflates unfulfilled quantity/value and misrepresents supply performance.
-- This model standardizes MTD sales and PO value metrics by introducing effective_order_qty and effective_po_value
-- logic to correctly calculate fill rate and unfulfilled value for multi-GRN channels.


WITH base AS (
    SELECT *
    FROM {{ ref('int_mtd_channel_sales') }}
),

final AS (
    SELECT
        sku_id,
        location_id,
        channel_name,
        month_start,
        is_multi_grn,

        mtd_order_qty,
        mtd_shipped_qty,
        mtd_effective_order_qty,
        mtd_effective_po_value,
        mtd_unfulfilled_value,

        ROUND(mtd_shipped_qty / NULLIF(mtd_order_qty, 0), 4) AS fill_rate,

        ROUND(mtd_unfulfilled_value / NULLIF(mtd_effective_po_value, 0), 4) AS unfulfilled_rate_by_value

    FROM base
)

SELECT * FROM final;
