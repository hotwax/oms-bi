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
  DATE_FORMAT(rh.ENTRY_DATE, "%Y-%m-%d %H:%i:%s") returnEntryDate,
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
  oh.ORDER_TYPE_ID AS orderTypeId,
  oh.ORDER_NAME AS orderName,
  oh.EXTERNAL_ID AS externalId,
  oh.SALES_CHANNEL_ENUM_ID AS salesChannelEnumId,
  DATE_FORMAT(oh.ORDER_DATE, "%Y-%m-%d %H:%i:%s") AS orderDate,
  DATE_FORMAT(oh.ENTRY_DATE, "%Y-%m-%d %H:%i:%s") AS orderEntryDate,
  oh.PRIORITY AS priority,
  oh.ORIGIN_FACILITY_ID AS orderOriginFacilityId,
  oh.PRODUCT_STORE_ID AS productStoreId,
  pa.CITY AS orderOrgCity,
  pa.POSTAL_CODE AS orderOrgPostalCode,
  pa.COUNTRY_GEO_ID AS orderOrgCountryGeoId,
  pa.STATE_PROVINCE_GEO_ID AS orderOrgStateProvinceGeoId,
  pa.MUNICIPALITY_GEO_ID AS orderOrgMunicipalityGeoId,
  pa.LONGITUDE AS orderOrgLongitude,
  pa.LATITUDE AS orderOrgLatitude,
  rh.CREATED_TX_STAMP cursorDate
FROM return_header rh
JOIN return_adjustment ra ON ra.RETURN_ID = rh.RETURN_ID AND ra.RETURN_ADJUSTMENT_TYPE_ID = "APPEASEMENT"
LEFT JOIN order_header oh ON oh.ORDER_ID = ra.ORDER_ID
LEFT JOIN (
  select ocm.order_id, ocm.CONTACT_MECH_ID
  FROM order_contact_mech ocm
  WHERE ocm.CONTACT_MECH_PURPOSE_TYPE_ID = "SHIPPING_LOCATION"
  group by ocm.order_id
) ocm1 on ocm1.order_id = oh.order_id
LEFT JOIN postal_address pa ON pa.CONTACT_MECH_ID = ocm1.CONTACT_MECH_ID