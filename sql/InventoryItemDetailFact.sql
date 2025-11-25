-- ******************************************************************
-- Base Query that fetches the Fact data
-- ******************************************************************
SELECT
  IID.INVENTORY_ITEM_ID as `INVENTORY_ITEM_ID`,
  IID.INVENTORY_ITEM_DETAIL_SEQ_ID as `INVENTORY_ITEM_DETAIL_SEQ_ID`,
  II.FACILITY_ID as `FACILITY_ID`,
  II.PRODUCT_ID as `PRODUCT_ID`,
  (
    SELECT
      PAC.average_cost
    FROM
      product_average_cost PAC
    WHERE
      II.product_id = PAC.product_id
      AND II.facility_id = PAC.facility_id
      AND PAC.product_average_cost_type_id = 'WEIGHTED_AVG_COST'
      AND (
        PAC.thru_date > IID.effective_date
        OR PAC.thru_date IS NULL
      )
    ORDER BY
      CASE WHEN PAC.thru_date IS NULL THEN 1 ELSE 0 END,
      PAC.thru_date
    LIMIT 1
    )
  as `AVERAGE_COST_POST_EVENT`,
  IID.EFFECTIVE_DATE as `EFFECTIVE_DATE`,
  date(IID.EFFECTIVE_DATE) as `EFFECTIVE_DATE_DIM_ID`,
  IID.QUANTITY_ON_HAND_DIFF as `QUANTITY_ON_HAND_DIFF`,
  IID.AVAILABLE_TO_PROMISE_DIFF as `AVAILABLE_TO_PROMISE_DIFF`,
  IID.ACCOUNTING_QUANTITY_DIFF as `ACCOUNTING_QUANTITY_DIFF`,
  IID.LAST_QUANTITY_ON_HAND as `QOH_BEFORE_DIFF`,
  IID.LAST_AVAILABLE_TO_PROMISE as `ATP_BEFORE_DIFF`,
  IID.REASON_ENUM_ID as `REASON_ENUM_ID`,
  IID.ORDER_ID as `ORDER_ID`,
  IID.ORDER_ITEM_SEQ_ID as `ORDER_ITEM_SEQ_ID`,
  IID.SHIP_GROUP_SEQ_ID as `SHIP_GROUP_SEQ_ID`,
  IID.SHIPMENT_ID as `SHIPMENT_ID`,
  IID.SHIPMENT_ITEM_SEQ_ID as `SHIPMENT_ITEM_SEQ_ID`,
  IID.RETURN_ID as `RETURN_ID`,
  IID.RETURN_ITEM_SEQ_ID as `RETURN_ITEM_SEQ_ID`,
  IID.ITEM_ISSUANCE_ID as `ITEM_ISSUANCE_ID`,
  IID.RECEIPT_ID as `RECEIPT_ID`,
  IID.effective_date as `cursorDate`,
  IIV.CHANGE_BY_USER_LOGIN_ID as `CHANGE_BY_USER_LOGIN`,
  IIV.COMMENTS as `COMMENTS`
FROM
  inventory_item_detail IID
JOIN
  inventory_item II
  ON IID.inventory_item_id = II.inventory_item_id
LEFT JOIN 
  inventory_item_variance IIV
  ON IID.inventory_item_id = IIV.inventory_item_id
  AND IID.physical_inventory_id = IIV.physical_inventory_id

