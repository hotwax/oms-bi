-- ******************************************************************
-- Base Query that fetches initial data (completed order)
-- ******************************************************************

SELECT 
    *,
    DATE(ITEM_COMPLETED_DATE) AS ITEM_COMPLETED_DATE_DIM_ID
FROM
(
    SELECT
        oh.ORDER_ID AS `ORDER_ID`,
        oi.ORDER_ITEM_SEQ_ID AS `ORDER_ITEM_SEQ_ID`,
        oh.EXTERNAL_ID AS `EXTERNAL_ID`,
        oi.EXTERNAL_ID AS `ITEM_EXTERNAL_ID`,
        oh.ORDER_NAME AS `ORDER_NAME`,
        oh.STATUS_ID AS `ORDER_STATUS`,
        oh.ORDER_TYPE_ID AS `ORDER_TYPE_ID`,
        oh.PRODUCT_STORE_ID AS `PRODUCT_STORE_ID`,
        oh.SALES_CHANNEL_ENUM_ID AS `SALES_CHANNEL_ENUM_ID`,
        oh.ENTRY_DATE AS `ENTRY_DATE`,
        oh.ORDER_DATE AS `ORDER_DATE`,
        DATE(oh.ORDER_DATE) AS `ORDER_DATE_DIM_ID`,
        (SELECT SUM(oa.amount)
         FROM order_adjustment oa
         WHERE oa.order_id = oh.order_id
           AND oa.order_adjustment_type_id IN ("SHIPPING_CHARGES", "SHIPPING_SALES_TAX", "EXT_SHIP_ADJUSTMENT")
        ) AS `SHIPPING_CHARGES`,
        oi.PRODUCT_ID AS `PRODUCT_ID`,
        oi.ITEM_DESCRIPTION AS `ITEM_DESCRIPTION`,
        oi.QUANTITY AS `QUANTITY`,
        oi.CANCEL_QUANTITY AS `CANCEL_QUANTITY`,
        oi.UNIT_PRICE AS `UNIT_PRICE`,
        oi.STATUS_ID AS `ITEM_STATUS_ID`,
        os.status_datetime AS `ITEM_COMPLETED_DATE`,
        os.status_user_login AS `FULFILLED_BY_USER_LOGIN_ID`,
        oisg.SHIPMENT_METHOD_TYPE_ID AS `SHIPMENT_METHOD_TYPE_ID`,
        oisg.LAST_UPDATED_STAMP AS `SHIP_GROUP_CREATED_STAMP`,
        oisg.FACILITY_ID AS `FACILITY_ID`,
        dpa.CONTACT_MECH_ID AS `DEST_CONTACT_MECH_ID`,
        dpa.STATE_PROVINCE_GEO_ID AS `DEST_STATE_PROVINCE_GEO_ID`,
        dpa.CITY AS `DEST_CITY`,
        dpa.ADDRESS1 AS `DEST_ADDRESS1`,
        dpa.POSTAL_CODE AS `DEST_POSTAL_CODE`,
        dpa.LATITUDE AS `DEST_LATITUDE`,
        dpa.LONGITUDE AS `DEST_LONGITUDE`,
        srs.TRACKING_ID_NUMBER AS `TRACKING_ID_NUMBER`,
        s.SHIPMENT_ID AS `SHIPMENT_ID`,
        oh.ORIGIN_FACILITY_ID AS `ORDER_ORIGIN_FACILITY_ID`,
        srs.ORIGIN_FACILITY_ID AS `ORIGIN_FACILITY_ID`,
        srs.DEST_FACILITY_ID AS `DEST_FACILITY_ID`,
        srs.ACTUAL_CARRIER_CODE AS `ACTUAL_CARRIER_CODE`,
        srs.ACTUAL_COST AS `ACTUAL_COST`,
        (SELECT SUM(AMOUNT)
         FROM order_adjustment oa
         WHERE oa.order_id = oi.order_id
           AND oa.order_item_seq_id = oi.order_item_seq_id
           AND oa.order_adjustment_type_id IN ("EXT_PROMO_ADJUSTMENT")
        ) AS `ITEM_DISC_PER_UNIT`,
        (SELECT SUM(AMOUNT)
         FROM order_adjustment oa
         WHERE oa.order_id = oi.order_id
           AND oa.order_item_seq_id = oi.order_item_seq_id
           AND oa.order_adjustment_type_id = "SALES_TAX"
        ) AS `ITEM_TAX_AMOUNT`,
        oh.PRIORITY AS `PRIORITY`,
        DATE_FORMAT(os.status_datetime, "%Y-%m-%d %H:%i:%s.%f") AS `cursorDateStrFormatted`,
        os.status_datetime cursorDate
    FROM order_item oi
    JOIN order_status os 
        ON os.order_id = oi.order_id
       AND oi.order_item_seq_id = os.order_item_seq_id
       AND os.status_id = "ITEM_COMPLETED"
    JOIN order_header oh
        ON oh.order_id = oi.order_id
       AND oh.ORDER_TYPE_ID = "SALES_ORDER"
    JOIN order_item_ship_group oisg
        ON oisg.order_id = oi.order_id
       AND oisg.SHIP_GROUP_SEQ_ID = oi.SHIP_GROUP_SEQ_ID
    LEFT JOIN order_shipment os1
        ON os1.order_id = oi.order_id
       AND os1.order_item_seq_id = oi.order_item_seq_id
       AND os1.ship_group_seq_id = oisg.ship_group_seq_id
    LEFT JOIN shipment s
        ON s.shipment_id = os1.shipment_id
    LEFT JOIN shipment_route_segment srs
        ON srs.shipment_id = s.shipment_id
    LEFT JOIN shipment_package_route_seg sprs
        ON sprs.shipment_id = srs.shipment_id
       AND sprs.shipment_route_segment_id = srs.shipment_route_segment_id
    LEFT JOIN postal_address dpa
        ON srs.DEST_CONTACT_MECH_ID = dpa.CONTACT_MECH_ID
    WHERE 
        (s.status_id = "SHIPMENT_SHIPPED" OR s.shipment_id IS NULL)
        AND oi.quantity = 1
        AND os.status_datetime = (
                SELECT MAX(mos.status_datetime)
                FROM order_status mos
                WHERE mos.order_id = os.order_id
                  AND mos.order_item_seq_id = os.order_item_seq_id
                  AND mos.status_id = "ITEM_COMPLETED"
        )
    ORDER BY os.status_datetime
) temp

-- ******************************************************************
-- SQL to fetch the remaining data, mainly status dates (Completed order)
-- ******************************************************************

WITH 
  order_status_slice AS (
    SELECT
      os.order_id,
      os.order_item_seq_id,
      os.status_datetime
    FROM
      order_status os
    WHERE
      os.status_id = 'ITEM_COMPLETED'
      AND os.status_datetime BETWEEN '${min_cursor}' AND '${max_cursor}'
  ),

  ranked_order_facility_change AS (
    SELECT
      ofc.order_id,
      ofc.order_item_seq_id,
      ofc.change_datetime,
      ofc.comments,
      ROW_NUMBER() OVER (
        PARTITION BY ofc.order_id, ofc.order_item_seq_id
        ORDER BY ofc.change_datetime DESC
      ) AS rn
    FROM
      order_facility_change ofc
    WHERE
      ofc.change_reason_enum_id = 'BROKERED'
  )

SELECT
  os.order_id AS `ORDER_ID`,
  os.order_item_seq_id AS `ORDER_ITEM_SEQ_ID`,
  os.status_datetime AS `ITEM_COMPLETED_DATE`,
  rofc.change_datetime AS `BROKERED_DATE`,
  rofc.comments AS `BROKERED_COMMENTS`,
  s.shipment_id AS `SHIPMENT_ID`,
  (
    SELECT MAX(osd.status_datetime)
    FROM order_status osd
    WHERE osd.order_id = os1.order_id
      AND osd.order_item_seq_id = os.order_item_seq_id
      AND osd.status_id = 'ITEM_CREATED'
  ) AS `ITEM_CREATED_DATE`,
  (
    SELECT MAX(osd.status_datetime)
    FROM order_status osd
    WHERE osd.order_id = os1.order_id
      AND osd.order_item_seq_id = os.order_item_seq_id
      AND osd.status_id = 'ITEM_APPROVED'
  ) AS `ITEM_APPROVED_DATE`,
  (
    SELECT MAX(osd.status_date)
    FROM shipment_status osd
    WHERE osd.shipment_id = os1.shipment_id
      AND osd.status_id = 'SHIPMENT_INPUT'
  ) AS `SHIPMENT_INPUT_DATE`,

  (
    SELECT MAX(osd.status_date)
    FROM shipment_status osd
    WHERE osd.shipment_id = os1.shipment_id
      AND osd.status_id = 'SHIPMENT_PACKED'
  ) AS `SHIPMENT_PACKED_DATE`,

  (
    SELECT MAX(osd.status_date)
    FROM shipment_status osd
    WHERE osd.shipment_id = os1.shipment_id
      AND osd.status_id = 'SHIPMENT_SHIPPED'
  ) AS `SHIPMENT_SHIPPED_DATE`

FROM
  order_status_slice os
  LEFT JOIN order_shipment os1
    ON os1.order_id = os.order_id
    AND os1.order_item_seq_id = os.order_item_seq_id
  LEFT JOIN shipment s
    ON s.shipment_id = os1.shipment_id
  LEFT JOIN ranked_order_facility_change rofc
    ON rofc.order_id = os.order_id
    AND rofc.order_item_seq_id = os.order_item_seq_id
    AND rofc.rn = 1

WHERE
  (
    s.shipment_type_id = 'SALES_SHIPMENT'
    AND s.status_id = 'SHIPMENT_SHIPPED'
  )
  OR s.shipment_id IS NULL;

-- ******************************************************************
-- Base Query that fetches initial data (Cancelled order)
-- ******************************************************************
SELECT 
    *,
    DATE(ITEM_CANCELLED_DATE) AS ITEM_CANCELLED_DATE_DIM_ID
FROM
(
    SELECT
        oh.ORDER_ID AS `ORDER_ID`,
        oi.ORDER_ITEM_SEQ_ID AS `ORDER_ITEM_SEQ_ID`,
        oh.EXTERNAL_ID AS `EXTERNAL_ID`,
        oi.EXTERNAL_ID AS `ITEM_EXTERNAL_ID`,
        oh.ORDER_NAME AS `ORDER_NAME`,
        oh.STATUS_ID AS `ORDER_STATUS`,
        oh.ORDER_TYPE_ID AS `ORDER_TYPE_ID`,
        oh.PRODUCT_STORE_ID AS `PRODUCT_STORE_ID`,
        oh.SALES_CHANNEL_ENUM_ID AS `SALES_CHANNEL_ENUM_ID`,
        oh.ENTRY_DATE AS `ENTRY_DATE`,
        oh.ORDER_DATE AS `ORDER_DATE`,
        DATE(oh.ORDER_DATE) AS `ORDER_DATE_DIM_ID`,
        (SELECT SUM(oa.amount)
         FROM order_adjustment oa
         WHERE oa.order_id = oh.order_id
           AND oa.order_adjustment_type_id IN ("SHIPPING_CHARGES", "SHIPPING_SALES_TAX", "EXT_SHIP_ADJUSTMENT")
        ) AS `SHIPPING_CHARGES`,
        oi.PRODUCT_ID AS `PRODUCT_ID`,
        oi.ITEM_DESCRIPTION AS `ITEM_DESCRIPTION`,
        oi.QUANTITY AS `QUANTITY`,
        oi.CANCEL_QUANTITY AS `CANCEL_QUANTITY`,
        oi.UNIT_PRICE AS `UNIT_PRICE`,
        oi.STATUS_ID AS `ITEM_STATUS_ID`,
        os.status_datetime AS `ITEM_CANCELLED_DATE`,
        os.status_user_login AS `FULFILLED_BY_USER_LOGIN_ID`,
        oisg.SHIPMENT_METHOD_TYPE_ID AS `SHIPMENT_METHOD_TYPE_ID`,
        oisg.LAST_UPDATED_STAMP AS `SHIP_GROUP_CREATED_STAMP`,
        oisg.FACILITY_ID AS `FACILITY_ID`,
        dpa.CONTACT_MECH_ID AS `DEST_CONTACT_MECH_ID`,
        dpa.STATE_PROVINCE_GEO_ID AS `DEST_STATE_PROVINCE_GEO_ID`,
        dpa.CITY AS `DEST_CITY`,
        dpa.ADDRESS1 AS `DEST_ADDRESS1`,
        dpa.POSTAL_CODE AS `DEST_POSTAL_CODE`,
        dpa.LATITUDE AS `DEST_LATITUDE`,
        dpa.LONGITUDE AS `DEST_LONGITUDE`,
        srs.TRACKING_ID_NUMBER AS `TRACKING_ID_NUMBER`,
        s.SHIPMENT_ID AS `SHIPMENT_ID`,
        oh.ORIGIN_FACILITY_ID AS `ORDER_ORIGIN_FACILITY_ID`,
        srs.ORIGIN_FACILITY_ID AS `ORIGIN_FACILITY_ID`,
        srs.DEST_FACILITY_ID AS `DEST_FACILITY_ID`,
        srs.ACTUAL_CARRIER_CODE AS `ACTUAL_CARRIER_CODE`,
        srs.ACTUAL_COST AS `ACTUAL_COST`,
        (SELECT SUM(AMOUNT)
         FROM order_adjustment oa
         WHERE oa.order_id = oi.order_id
           AND oa.order_item_seq_id = oi.order_item_seq_id
           AND oa.order_adjustment_type_id IN ("EXT_PROMO_ADJUSTMENT")
        ) AS `ITEM_DISC_PER_UNIT`,
        (SELECT SUM(AMOUNT)
         FROM order_adjustment oa
         WHERE oa.order_id = oi.order_id
           AND oa.order_item_seq_id = oi.order_item_seq_id
           AND oa.order_adjustment_type_id = "SALES_TAX"
        ) AS `ITEM_TAX_AMOUNT`,
        oh.PRIORITY AS `PRIORITY`,
        DATE_FORMAT(os.status_datetime, "%Y-%m-%d %H:%i:%s.%f") AS `cursorDateStrFormatted`,
        os.status_datetime cursorDate
    FROM order_item oi
    JOIN order_status os 
        ON os.order_id = oi.order_id
       AND oi.order_item_seq_id = os.order_item_seq_id
       AND os.status_id = "ITEM_CANCELLED"
    JOIN order_header oh
        ON oh.order_id = oi.order_id
       AND oh.ORDER_TYPE_ID = "SALES_ORDER"
    LEFT JOIN order_item_ship_group oisg
        ON oisg.order_id = oi.order_id
       AND oisg.SHIP_GROUP_SEQ_ID = oi.SHIP_GROUP_SEQ_ID
    LEFT JOIN order_shipment os1
        ON os1.order_id = oi.order_id
       AND os1.order_item_seq_id = oi.order_item_seq_id
       AND os1.ship_group_seq_id = oisg.ship_group_seq_id
    LEFT JOIN shipment s
        ON s.shipment_id = os1.shipment_id
    LEFT JOIN shipment_route_segment srs
        ON srs.shipment_id = s.shipment_id
    LEFT JOIN shipment_package_route_seg sprs
        ON sprs.shipment_id = srs.shipment_id
       AND sprs.shipment_route_segment_id = srs.shipment_route_segment_id
    LEFT JOIN postal_address dpa
        ON srs.DEST_CONTACT_MECH_ID = dpa.CONTACT_MECH_ID
    WHERE 
        (s.status_id <> "SHIPMENT_SHIPPED" OR s.shipment_id IS NULL)
        AND oi.quantity = 1
        AND os.status_datetime = (
                SELECT MAX(mos.status_datetime)
                FROM order_status mos
                WHERE mos.order_id = os.order_id
                  AND mos.order_item_seq_id = os.order_item_seq_id
                  AND mos.status_id = "ITEM_CANCELLED"
        )
) temp
-- ******************************************************************
-- SQL to fetch the remaining data, mainly status dates (Cancelled order)
-- ******************************************************************

WITH 
  order_status_slice AS (
    SELECT
      os.order_id,
      os.order_item_seq_id,
      os.status_datetime
    FROM
      order_status os
    WHERE
      os.status_id = 'ITEM_CANCELLED'
      AND os.status_datetime BETWEEN '${min_cursor}' AND '${max_cursor}'
  ),

  ranked_order_facility_change AS (
    SELECT
      ofc.order_id,
      ofc.order_item_seq_id,
      ofc.change_datetime,
      ofc.comments,
      ROW_NUMBER() OVER (
        PARTITION BY ofc.order_id, ofc.order_item_seq_id
        ORDER BY ofc.change_datetime DESC
      ) AS rn
    FROM
      order_facility_change ofc
    WHERE
      ofc.change_reason_enum_id = 'BROKERED'
  )

SELECT
  os.order_id AS `ORDER_ID`,
  os.order_item_seq_id AS `ORDER_ITEM_SEQ_ID`,
  os.status_datetime AS `ITEM_CANCELLED_DATE`,
  rofc.change_datetime AS `BROKERED_DATE`,
  rofc.comments AS `BROKERED_COMMENTS`,
  s.shipment_id AS `SHIPMENT_ID`,
  (
    SELECT MAX(osd.status_datetime)
    FROM order_status osd
    WHERE osd.order_id = os.order_id
      AND osd.order_item_seq_id = os.order_item_seq_id
      AND osd.status_id = 'ITEM_CREATED'
  ) AS `ITEM_CREATED_DATE`,
  (
    SELECT MAX(osd.status_datetime)
    FROM order_status osd
    WHERE osd.order_id = os.order_id
      AND osd.order_item_seq_id = os.order_item_seq_id
      AND osd.status_id = 'ITEM_APPROVED'
  ) AS `ITEM_APPROVED_DATE`,
  (
    SELECT MAX(osd.status_date)
    FROM shipment_status osd
    WHERE osd.shipment_id = os1.shipment_id
      AND osd.status_id = 'SHIPMENT_INPUT'
  ) AS `SHIPMENT_INPUT_DATE`,

  (
    SELECT MAX(osd.status_date)
    FROM shipment_status osd
    WHERE osd.shipment_id = os1.shipment_id
      AND osd.status_id = 'SHIPMENT_PACKED'
  ) AS `SHIPMENT_PACKED_DATE`

FROM
  order_status_slice os
  LEFT JOIN order_shipment os1
    ON os1.order_id = os.order_id
    AND os1.order_item_seq_id = os.order_item_seq_id
  LEFT JOIN shipment s
    ON s.shipment_id = os1.shipment_id
  LEFT JOIN ranked_order_facility_change rofc
    ON rofc.order_id = os.order_id
    AND rofc.order_item_seq_id = os.order_item_seq_id
    AND rofc.rn = 1

WHERE
  (
    s.shipment_type_id = 'SALES_SHIPMENT'
    AND s.status_id <> 'SHIPMENT_SHIPPED'
  )
  OR s.shipment_id IS NULL;


-- ******************************************************************
-- Query to combine whole data
-- ******************************************************************

SELECT o.*, e.* 
FROM original o
LEFT JOIN enrichment e
ON o.ORDER_ID = e.ORDER_ID
and o.ORDER_ITEM_SEQ_ID = e.ORDER_ITEM_SEQ_ID
and o.SHIPMENT_ID = e.SHIPMENT_ID

-- ******************************************************************
-- Query to combine whole data (Cancelled orders)
-- ******************************************************************

SELECT o.*, e.* 
FROM original o
LEFT JOIN enrichment e
ON o.ORDER_ID = e.ORDER_ID
and o.ORDER_ITEM_SEQ_ID = e.ORDER_ITEM_SEQ_ID

