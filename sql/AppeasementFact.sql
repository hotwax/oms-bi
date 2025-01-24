SELECT
  rh.RETURN_ID returnId,
  (
    SELECT rtni.ID_VALUE
    FROM return_identification rtni
    WHERE rtni.RETURN_ID = rh.RETURN_ID
      AND rtni.RETURN_IDENTIFICATION_TYPE_ID = "SHOPIFY_RTN_ID"
      AND (rtni.THRU_DATE > NOW() OR rtni.THRU_DATE IS NULL)
  ) externalReturnId,
  "SHOPIFY" dataSourceId,
  DATE_FORMAT(rh.RETURN_DATE, "%Y-%m-%d %H:%i:%s") returnDate,
  ra.ORDER_ID orderId,
  ra.COMMENTS comments,
  ra.DESCRIPTION description,
  ra.AMOUNT amount,
  rh.RETURN_HEADER_TYPE_ID returnTypeId,
  rh.DESTINATION_FACILITY_ID destinationFacilityId,
  rh.EMPLOYEE_ID employeeId,
  rh.CREATED_BY createdByUserLogin,
  rh.RETURN_CHANNEL_ENUM_ID returnChannelEnumId,
  rh.STATUS_ID returnStatusId,
  (
    SELECT SUM(opp.MAX_AMOUNT)
    FROM return_item_response ris
    JOIN order_payment_preference opp ON opp.ORDER_PAYMENT_PREFERENCE_ID = ris.ORDER_PAYMENT_PREFERENCE_ID
    WHERE ris.RETURN_ID = rh.RETURN_ID
      AND ris.RETURN_ITEM_SEQ_ID = "_NA_"
      AND opp.STATUS_ID = "PAYMENT_REFUNDED"
  ) returnRefundedTotal,
  rh.CREATED_TX_STAMP cursorDate
FROM return_header rh
JOIN return_adjustment ra ON ra.RETURN_ID = rh.RETURN_ID
    AND ra.RETURN_ADJUSTMENT_TYPE_ID = "APPEASEMENT"