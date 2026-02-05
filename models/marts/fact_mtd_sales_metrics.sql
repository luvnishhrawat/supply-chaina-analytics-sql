-- Model: fact_mtd_sales_metrics
-- Layer: mart
-- Description: Standardized MTD sales, fulfillment and PO value metrics with multi-GRN channel handling
-- Grain: sku_id, location_id, channel_name, month_start
-- Downstream use: AWS QuickSight dashboards

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
