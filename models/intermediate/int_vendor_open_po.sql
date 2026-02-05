-- Model: int_vendor_open_po
-- Layer: intermediate
-- Description: Vendor open PO quantities (MTD) and latest inbound date by SKU code and city
-- Grain: sku_code, city

WITH open_po AS (
    SELECT 
        s.code AS sku_code,
        l.city,
        poli.open_quantity,
        po.po_date
    FROM purchase_order_line_items poli
    INNER JOIN skus s 
        ON s.id = poli.sku_id
    INNER JOIN purchase_orders po 
        ON po.id = poli.purchase_order_id
    LEFT JOIN locations l 
        ON l.id = po.location_id
    WHERE po.status <> 'Cancelled'
      AND poli.inbound_date IS NULL
      AND YEAR(po.po_date) = YEAR(CURRENT_DATE)
      AND MONTH(po.po_date) = MONTH(CURRENT_DATE)
),

vendor_open AS (
    SELECT 
        sku_code,
        city,
        SUM(open_quantity) AS vendor_open_qty
    FROM open_po
    GROUP BY 1,2
),

latest_inbound AS (
    SELECT
        s.code AS sku_code, 
        MAX(poli.inbound_date) AS latest_inbound_date
    FROM purchase_order_line_items poli
    INNER JOIN skus s 
        ON s.id = poli.sku_id
    INNER JOIN purchase_orders po
        ON po.id = poli.purchase_order_id
    WHERE poli.inbound_date IS NOT NULL
      AND po.status <> 'Cancelled'
    GROUP BY 1
)

SELECT
    vo.sku_code,
    vo.city,
    vo.vendor_open_qty,
    li.latest_inbound_date
FROM vendor_open vo
LEFT JOIN latest_inbound li
    ON li.sku_code = vo.sku_code;
