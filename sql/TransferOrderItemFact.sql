-- ******************************************************************
-- Base Query 1 that fetches Initial data
-- ******************************************************************
WITH order_item_status as (
    SELECT
      oh.order_id,
      oi.order_item_seq_id,
      os.status_id,
      os.status_user_login,
      os.status_datetime
    FROM order_header oh
      JOIN order_item oi ON oh.order_type_id = 'TRANSFER_ORDER' and oh.status_id in ('ORDER_COMPLETED', 'ORDER_CANCELLED') and oh.order_id = oi.ORDER_ID and oi.status_id in ('ITEM_COMPLETED', 'ITEM_CANCELLED')
      JOIN order_status os ON oi.ORDER_ID = os.ORDER_ID AND oi.ORDER_ITEM_SEQ_ID = os.ORDER_ITEM_SEQ_ID and os.status_id in ('ITEM_COMPLETED', 'ITEM_CANCELLED')
)
SELECT
  oh.order_id as `ORDER_ID`,
  oh.order_name as `ORDER_NAME`,
  oh.external_id as `EXTERNAL_ID`,
  oh.entry_date as `ORDER_ENTRY_DATE`,
  date(oh.entry_date) as `ORDER_ENTRY_DATE_DIM_ID`,
  oh.status_id as `ORDER_STATUS`,
  oh.priority as `PRIORITY`,
  oh.status_flow_id as `STATUS_FLOW_ID`,
  oh.order_date as `ORDER_DATE`,
  date(oh.order_date) as `ORDER_DATE_DIM_ID`,
  CASE
        WHEN os.status_id = 'ORDER_COMPLETED' THEN os.status_datetime
  END AS `ORDER_COMPLETION_DATE`,
  CASE
        WHEN os.status_id = 'ORDER_COMPLETED' THEN date(os.status_datetime)
  END AS `ORDER_COMPLETION_DATE_DIM_ID`,
  CASE
        WHEN os.status_id = 'ORDER_CANCELLED' THEN os.status_datetime
  END AS `ORDER_CANCELLATION_DATE`,
  CASE
        WHEN os.status_id = 'ORDER_CANCELLED' THEN date(os.status_datetime)
  END AS `ORDER_CANCELLATION_DATE_DIM_ID`,
  os.status_user_login as `STATUS_USER_LOGIN_ID`,
  oh.sales_channel_enum_id as `SALES_CHANNEL_ENUM_ID`,
  oh.product_store_id as `PRODUCT_STORE_ID`,
  oi.requested_ship_meth_type_id as `REQUESTED_SHIP_METH_TYPE_ID`,
  oi.order_item_seq_id as `ORDER_ITEM_SEQ_ID`,
  oi.external_id as `ITEM_EXTERNAL_ID`,
  oi.status_id as `ORDER_ITEM_STATUS_ID`,
  CASE
        WHEN ois.status_id = 'ITEM_COMPLETED' THEN ois.status_datetime
  END AS `ORDER_ITEM_COMPLETION_DATE`,
    CASE
        WHEN ois.status_id = 'ITEM_COMPLETED' THEN date(ois.status_datetime)
  END AS `ORDER_ITEM_COMPLETION_DATE_DIM_ID`,
  CASE
        WHEN ois.status_id = 'ITEM_CANCELLED' THEN ois.status_datetime
  END AS `ORDER_ITEM_CANCELLATION_DATE`,
   CASE
        WHEN ois.status_id = 'ITEM_CANCELLED' THEN date(ois.status_datetime)
  END AS `ORDER_ITEM_CANCELLATION_DATE_DIM_ID`,
  ois.status_user_login as `ITEM_STATUS_USER_LOGIN_ID`,
  oi.quantity as `ORDERED_QUANTITY`,
  osh.quantity as `SHIPPED_QUANTITY`,
  ss.status_date as `SHIPPED_DATE`,
  sr.quantity_accepted as `RECEIVED_QUANTITY`,
  sr.datetime_received as `RECEIVED_DATE`,
  ss.shipment_id as `SHIPMENT_ID`,
  oi.product_id as `PRODUCT_ID`,
  oi.item_description as `ITEM_DESCRIPTION`,
  oi.cancel_quantity as `CANCEL_QUANTITY`,
  oisg.facility_id as `ORIGIN_FACILITY_ID`,
  oisg.order_facility_id as `DESTINATION_FACILITY_ID`,
  date_format(oh.entry_date, "%Y-%m-%d %H:%i:%s.%f") AS `cursorDateStrFormatted`,
  os.status_datetime as `cursorDate`
FROM
  order_header oh
  JOIN order_item oi ON oh.order_id = oi.order_id and oh.order_type_id = 'TRANSFER_ORDER' and oh.status_id IN ('ORDER_COMPLETED', 'ORDER_CANCELLED')
  JOIN order_status os ON oh.order_id = os.order_id and os.status_id in ('ORDER_COMPLETED', 'ORDER_CANCELLED')
  JOIN order_item_status ois ON oh.order_id = ois.order_id and oi.order_item_seq_id = ois.order_item_seq_id
  LEFT JOIN order_shipment osh on oh.order_id = osh.order_id and oi.order_item_seq_id = osh.order_item_seq_id and oi.ship_group_seq_id = osh.ship_group_seq_id
  LEFT JOIN shipment_status ss on osh.shipment_id = ss.shipment_Id and ss.status_id = 'SHIPMENT_SHIPPED'
  LEFT JOIN shipment_receipt sr on osh.shipment_id = sr.shipment_id and osh.shipment_item_seq_id = sr.shipment_item_seq_id
  LEFT JOIN order_item_ship_group oisg on oh.order_id = oisg.order_id and oi.ship_group_seq_id = oisg.ship_group_seq_id

-- ******************************************************************
-- Base Query 2 that fetches Manual Reciept data
-- ******************************************************************
WITH manual_receipts AS (
    SELECT
        sr.ORDER_ID,
        sr.PRODUCT_ID,
        SUM(sr.QUANTITY_ACCEPTED) AS received_qty,
        MAX(sr.datetime_received) AS received_date
    FROM SHIPMENT_RECEIPT sr
    WHERE sr.ORDER_ITEM_SEQ_ID IS NULL
      AND sr.ORDER_ID IS NOT NULL
    GROUP BY sr.ORDER_ID, sr.PRODUCT_ID
)
SELECT
  oh.order_id as `ORDER_ID`,
  oh.order_name as `ORDER_NAME`,
  oh.external_id as `EXTERNAL_ID`,
  oh.entry_date as `ORDER_ENTRY_DATE`,
  date(oh.entry_date) as `ORDER_ENTRY_DATE_DIM_ID`,
  oh.status_id as `ORDER_STATUS`,
  oh.priority as `PRIORITY`,
  oh.status_flow_id as `STATUS_FLOW_ID`,
  oh.order_date as `ORDER_DATE`,
  date(oh.order_date) as `ORDER_DATE_DIM_ID`,
  CASE
        WHEN os.status_id = 'ORDER_COMPLETED' THEN os.status_datetime
  END AS `ORDER_COMPLETION_DATE`,
   CASE
        WHEN os.status_id = 'ORDER_COMPLETED' THEN date(os.status_datetime)
  END AS `ORDER_COMPLETION_DATE_DIM_ID`,
  CASE
        WHEN os.status_id = 'ORDER_CANCELLED' THEN os.status_datetime
  END AS `ORDER_CANCELLATION_DATE`,
   CASE
        WHEN os.status_id = 'ORDER_CANCELLED' THEN date(os.status_datetime)
  END AS `ORDER_CANCELLATION_DATE_DIM_ID`,
  os.status_user_login as `STATUS_USER_LOGIN_ID`,
  oh.sales_channel_enum_id as `SALES_CHANNEL_ENUM_ID`,
  oh.product_store_id as `PRODUCT_STORE_ID`,
  NULL as `REQUESTED_SHIP_METH_TYPE_ID`,
  NULL as `ORDER_ITEM_SEQ_ID`,
  NULL as `ITEM_EXTERNAL_ID`,
  'Manually Added' as `ORDER_ITEM_STATUS_ID`,
  NULL AS `ORDER_ITEM_COMPETION_DATE`,
  NULL AS `ORDER_ITEM_COMPLETION_DATE_DIM_ID`,
  NULL AS `ORDER_ITEM_CANCELLATION_DATE`,
  NULL AS `ORDER_ITEM_CANCELLATION_DATE_DIM_ID`,
  NULL AS `ITEM_STATUS_USER_LOGIN_ID`,
  0 as `ORDERED_QUANTITY`,
  0 as `SHIPPED_QUANTITY`,
  NULL as `SHIPPED_DATE`,
  mr.received_qty as `RECEIVED_QUANTITY`,
  mr.received_date as `RECEIVED_DATE`,
  NULL as `SHIPMENT_ID`,
  mr.product_id as `PRODUCT_ID`,
  NULL as `ITEM_DESCRIPTION`,
  NULL as `CANCEL_QUANTITY`,
  oisg.facility_id as `ORIGIN_FACILITY_ID`,
  oisg.order_facility_id as `DESTINATION_FACILITY_ID`,
  os.status_datetime as `cursorDate`

FROM
    manual_receipts mr
    JOIN order_header oh ON mr.order_id = oh.order_id and oh.order_type_id = 'TRANSFER_ORDER' and oh.status_id IN ('ORDER_COMPLETED', 'ORDER_CANCELLED')
    JOIN order_status os ON oh.order_id = os.order_id and os.status_id in ('ORDER_COMPLETED', 'ORDER_CANCELLED')
    JOIN order_item_ship_group oisg ON oh.ORDER_ID = oisg.ORDER_ID

-- ******************************************************************
-- SQL to fetch the remaining data, mainly item creation status date
-- ******************************************************************
with
  order_status_slice as (
    select
      os.order_id,
      os.order_item_seq_id,
      os.status_datetime
    from
      order_status os
    where
      os.status_id = "ITEM_CREATED"
      and (
        os.status_datetime between '${min_cursor}' and '${max_cursor}'
      )
  )
select
  order_id AS `ORDER_ID`,
  order_item_seq_id AS `ORDER_ITEM_SEQ_ID`,
  status_datetime AS `ORDER_ITEM_CREATION_DATE`,
  date(status_datetime) AS `ORDER_ITEM_CREATION_DATE_DIM_ID`
from
  order_status_slice

-- ******************************************************************
-- Query to combine whole data
-- ******************************************************************
    SELECT o.*, e.*
    FROM original o
    LEFT JOIN enrichment e
    ON o.ORDER_ID = e.ORDER_ID
    and o.ORDER_ITEM_SEQ_ID = e.ORDER_ITEM_SEQ_ID

