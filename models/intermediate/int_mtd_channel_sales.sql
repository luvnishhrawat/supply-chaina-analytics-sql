-- Model: int_mtd_channel_sales
-- Layer: intermediate
-- Description: MTD sales and PO metrics with multi-GRN channel handling
-- Grain: sku_id, location_id, channel_name, month_start

WITH base AS (
    SELECT
        ii.sku_id,
        co.location_id,
        DATE_TRUNC('month', i.invoice_date) AS month_start,
        
        CASE 
            WHEN c.name IS NULL THEN 'Others'
            ELSE c.name
        END AS channel_name,

        ii.order_quantity,
        ii.shipped_quantity,
        ii.tax_amount,
        ii.unit_price,

        CASE 
            WHEN c.name IN ('Etrade','Clicktech','Cocoblu','RK World','Flipkart B2B','Myntra') THEN 1 
            ELSE 0 
        END AS is_multi_grn

    FROM invoices i
    INNER JOIN invoice_items ii ON ii.invoice_id = i.id
    INNER JOIN channel_orders co ON co.id = i.channel_order_id
    LEFT JOIN channels c ON co.channel_id = c.id

    WHERE co.order_id NOT LIKE 'OD%'
      AND co.order_id NOT LIKE 'FBA%'
      AND co.order_id NOT LIKE 'FK%'
      AND i.invoice_date >= DATE_TRUNC('month', CURRENT_DATE)
),

final AS (
    SELECT
        sku_id,
        location_id,
        channel_name,
        month_start,
        is_multi_grn,

        SUM(order_quantity) AS mtd_order_qty,
        SUM(shipped_quantity) AS mtd_shipped_qty,

        SUM(
            CASE 
                WHEN is_multi_grn = 1 AND shipped_quantity < order_quantity THEN shipped_quantity
                ELSE order_quantity
            END
        ) AS mtd_effective_order_qty,

        SUM(
            CASE 
                WHEN is_multi_grn = 1 AND shipped_quantity < order_quantity THEN 
                    ((shipped_quantity * unit_price) - tax_amount)
                ELSE ((order_quantity * unit_price) - tax_amount)
            END
        ) AS mtd_effective_po_value,

        SUM(
            CASE 
                WHEN is_multi_grn = 1 AND shipped_quantity < order_quantity THEN 0
                ELSE ROUND(
                    ((order_quantity * unit_price) - tax_amount)
                    -
                    ((shipped_quantity * unit_price) - tax_amount)
                ,2)
            END
        ) AS mtd_unfulfilled_value

    FROM base
    GROUP BY 1,2,3,4,5
)

SELECT * FROM final;
