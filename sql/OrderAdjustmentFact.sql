-- *****************************************************************
-- Query to fetch the Adjustments for the OrderItemFulfillmentFact
-- *****************************************************************

WITH
order_status_slice AS (
  SELECT
    os.ORDER_ID,
    os.ORDER_ITEM_SEQ_ID
  FROM
    order_status os
  WHERE
    os.STATUS_ID = 'ITEM_COMPLETED'
    AND (
      os.CREATED_TX_STAMP BETWEEN '${min_cursor}' AND '${max_cursor}'
    )
)
SELECT
  os.ORDER_ID AS orderId,
  os.ORDER_ITEM_SEQ_ID AS orderItemSeqId,
  (
    SELECT SUM(oa.AMOUNT)
    FROM order_adjustment oa
    WHERE oa.ORDER_ID = os.ORDER_ID 
      AND oa.ORDER_ITEM_SEQ_ID = '_NA_'
      AND oa.ORDER_ADJUSTMENT_TYPE_ID = 'SHIPPING_CHARGES'
  ) AS shippingCharges,
  (
    SELECT SUM(oa.AMOUNT)
    FROM order_adjustment oa
    WHERE oa.ORDER_ID = os.ORDER_ID 
      AND oa.ORDER_ITEM_SEQ_ID = '_NA_'
      AND oa.ORDER_ADJUSTMENT_TYPE_ID = 'SHIPPING_SALES_TAX'
  ) AS shippingSalesTax,
  (
    SELECT SUM(oa.AMOUNT)
    FROM order_adjustment oa
    WHERE oa.ORDER_ID = os.ORDER_ID 
      AND oa.ORDER_ITEM_SEQ_ID = '_NA_'
      AND oa.ORDER_ADJUSTMENT_TYPE_ID = 'EXT_SHIP_ADJUSTMENT'
  ) AS extShipAdjustment,
  (
    SELECT SUM(oa.AMOUNT)
    FROM order_adjustment oa
    WHERE oa.ORDER_ID = os.ORDER_ID 
      AND oa.ORDER_ITEM_SEQ_ID = os.ORDER_ITEM_SEQ_ID
      AND oa.ORDER_ADJUSTMENT_TYPE_ID = 'EXT_PRICE_OVERRIDE'
  ) AS extPriceOverride,
  (
    SELECT SUM(oa.AMOUNT)
    FROM order_adjustment oa
    WHERE oa.ORDER_ID = os.ORDER_ID 
      AND oa.ORDER_ITEM_SEQ_ID = os.ORDER_ITEM_SEQ_ID
      AND oa.ORDER_ADJUSTMENT_TYPE_ID = 'EXT_FEES_ADJUSTMENT'
  ) AS extFeesAdjustment,
  (
    SELECT SUM(oa.AMOUNT)
    FROM order_adjustment oa
    WHERE oa.ORDER_ID = os.ORDER_ID 
      AND oa.ORDER_ITEM_SEQ_ID = os.ORDER_ITEM_SEQ_ID
      AND oa.ORDER_ADJUSTMENT_TYPE_ID = 'EXT_REWARDS'
  ) AS extRewards,
  (
    SELECT SUM(oa.AMOUNT)
    FROM order_adjustment oa
    WHERE oa.ORDER_ID = os.ORDER_ID 
      AND oa.ORDER_ITEM_SEQ_ID = os.ORDER_ITEM_SEQ_ID
      AND oa.ORDER_ADJUSTMENT_TYPE_ID = 'EXT_TRANS_ADJUSTMENT'
  ) AS extTransAdjustment
FROM
  order_status_slice os