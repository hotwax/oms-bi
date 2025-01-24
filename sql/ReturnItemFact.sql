SELECT
  ri.RETURN_ID returnId,
  ri.RETURN_ITEM_SEQ_ID returnItemSeqId,
  ri.RETURN_PRICE returnPrice,
  ri.DESCRIPTION returnItemDescription,
  ri.RETURN_ITEM_TYPE_ID returnItemTypeId,
  rh.RETURN_HEADER_TYPE_ID returnTypeId,
  DATE_FORMAT(rh.RETURN_DATE, "%Y-%m-%d %H:%i:%s") returnDate,
  rh.STATUS_ID returnStatusId,
  ri.STATUS_ID returnItemStatusId,
  rh.DESTINATION_FACILITY_ID destinationFacilityId,
  rh.EMPLOYEE_ID employeeId,
  rh.CREATED_BY createdByUserLogin,
  rh.RETURN_CHANNEL_ENUM_ID returnChannelEnumId,
  ri.RETURN_REASON_ID returnReasonId,
  ri.RECEIVED_QUANTITY receivedQuantity,
  ri.RETURN_QUANTITY returnQuantity,
  ri.ORDER_ID orderId,
  ri.ORDER_ITEM_SEQ_ID orderItemSeqId,
  ri.PRODUCT_ID productId,
  (
    SELECT rtni.ID_VALUE
    FROM return_identification rtni
    WHERE rtni.RETURN_ID = rh.RETURN_ID
      AND rtni.RETURN_IDENTIFICATION_TYPE_ID = "SHOPIFY_RTN_ID"
      AND (thru_date > NOW() OR thru_date IS NULL)
  ) externalReturnId,
  "SHOPIFY" dataSourceId,
  ris.SHIPMENT_ID returnShipmentId,
  (
    SELECT SUM(opp.MAX_AMOUNT)
    FROM return_item_response ris
    JOIN order_payment_preference opp ON opp.ORDER_PAYMENT_PREFERENCE_ID = ris.ORDER_PAYMENT_PREFERENCE_ID
    WHERE ris.RETURN_ID = rh.RETURN_ID
      AND ris.RETURN_ITEM_SEQ_ID = "_NA_"
      AND opp.STATUS_ID = "PAYMENT_REFUNDED"
  ) returnRefundedTotal,
  (
    SELECT SUM(ra.AMOUNT)
    FROM return_adjustment ra
    WHERE ra.RETURN_ID = ri.RETURN_ID
      AND ra.RETURN_ITEM_SEQ_ID = ri.RETURN_ITEM_SEQ_ID
      AND ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_EXT_PRM_ADJ'
      AND ra.RETURN_TYPE_ID = 'RTN_REFUND'
  ) returnDiscountAmt,
  (
    SELECT SUM(ra.AMOUNT)
    FROM return_adjustment ra
    WHERE ra.RETURN_ID = ri.RETURN_ID
      AND ra.RETURN_ITEM_SEQ_ID = ri.RETURN_ITEM_SEQ_ID
      AND ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_SALES_TAX_ADJ'
      AND ra.RETURN_TYPE_ID = 'RTN_REFUND'
  ) totalTaxRefundAmt,
  (
    SELECT SUM(ra.AMOUNT)
    FROM return_adjustment ra
    WHERE ra.RETURN_ID = ri.RETURN_ID
      AND ra.RETURN_ITEM_SEQ_ID = "_NA_"
      AND ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_SHIPPING_ADJ'
      AND ra.RETURN_TYPE_ID = 'RTN_REFUND'
  ) returnShippingAmt,
  DATE_FORMAT(rs.STATUS_DATETIME, "%Y-%m-%d %H:%i:%s") returnItemCompletedDate,
  DATE_FORMAT(rs1.STATUS_DATETIME, "%Y-%m-%d %H:%i:%s") returnItemReceivedDate,
  rs1.CHANGE_BY_USER_LOGIN_ID receivedByUserLogin,
  rs.CREATED_TX_STAMP cursorDate
FROM return_item ri
JOIN return_header rh ON rh.RETURN_ID = ri.RETURN_ID
JOIN return_status rs ON rs.RETURN_ID = ri.RETURN_ID
    AND rs.RETURN_ITEM_SEQ_ID = ri.RETURN_ITEM_SEQ_ID
    AND ri.STATUS_ID = rs.STATUS_ID
    AND ri.STATUS_ID = "RETURN_COMPLETED"
LEFT JOIN return_status rs1 ON rs1.RETURN_ID = ri.RETURN_ID
    AND rs1.RETURN_ITEM_SEQ_ID = ri.RETURN_ITEM_SEQ_ID
    AND rs1.STATUS_ID = "RETURN_RECEIVED"
LEFT JOIN return_item_shipment ris ON ris.RETURN_ID = ri.RETURN_ID
    AND ris.RETURN_ITEM_SEQ_ID = ri.RETURN_ITEM_SEQ_ID