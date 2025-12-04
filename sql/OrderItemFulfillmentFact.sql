-- ******************************************************************
-- Base Query that fetches initial data (completed order)
-- ******************************************************************
select
  *,
  date(ITEM_COMPLETED_DATE) as ITEM_COMPLETED_DATE_DIM_ID
from
  (
    select
      oh.ORDER_ID AS `ORDER_ID`,
      oh.status_id AS `ORDER_STATUS`,
      oi.ORDER_ITEM_SEQ_ID AS `ORDER_ITEM_SEQ_ID`,
      oh.EXTERNAL_ID AS `EXTERNAL_ID`,
      oi.EXTERNAL_ID AS `ITEM_EXTERNAL_ID`,
      oh.ORDER_NAME AS `ORDER_NAME`,
      oh.ORDER_TYPE_ID AS `ORDER_TYPE_ID`,
      oh.PRODUCT_STORE_ID AS `PRODUCT_STORE_ID`,
      oh.SALES_CHANNEL_ENUM_ID AS `SALES_CHANNEL_ENUM_ID`,
      oh.ENTRY_DATE AS `ENTRY_DATE`,
      oh.ORDER_DATE AS `ORDER_DATE`,
      date(oh.ORDER_DATE) AS `ORDER_DATE_DIM_ID`,
      (
        select
          sum(oa.amount)
        from
          order_adjustment oa
        where
          oa.order_id = oh.order_id
          and oa.order_adjustment_type_id in ("SHIPPING_CHARGES", "SHIPPING_SALES_TAX", "EXT_SHIP_ADJUSTMENT")
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
      oisg.CREATED_STAMP AS `SHIP_GROUP_CREATED_STAMP`,
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
      (
        select
          sum(AMOUNT)
        from
          order_adjustment oa
        where
          oa.order_id = oi.order_id
          and oa.order_item_seq_id = oi.order_item_seq_id
          and oa.order_adjustment_type_id in ("EXT_PROMO_ADJUSTMENT")
      ) AS `ITEM_DISC_PER_UNIT`,
      (
        select
          sum(AMOUNT)
        from
          order_adjustment oa
        where
          oa.order_id = oi.order_id
          and oa.order_item_seq_id = oi.order_item_seq_id
          and oa.order_adjustment_type_id = "SALES_TAX"
      ) AS `ITEM_TAX_AMOUNT`,
      oh.PRIORITY AS `PRIORITY`,
      date_format(os.created_tx_stamp, "%Y-%m-%d %H:%i:%s.%f") AS `cursorDateStrFormatted`,
      os.created_tx_stamp cursorDate
    from
      order_item oi
      join order_status os on os.order_id = oi.order_id
      and oi.order_item_seq_id = os.order_item_seq_id
      and os.status_id = "ITEM_COMPLETED"
      join order_header oh on oh.order_id = oi.order_id
      and oh.ORDER_TYPE_ID = "SALES_ORDER"
      join order_item_ship_group oisg on oisg.order_id = oi.order_id
      and oisg.SHIP_GROUP_SEQ_ID = oi.SHIP_GROUP_SEQ_ID
      left join order_shipment os1 on os1.order_id = oi.order_id
      and os1.order_item_seq_id = oi.order_item_seq_id
      and os1.ship_group_seq_id = oisg.ship_group_seq_id
      left join shipment s on s.shipment_id = os1.shipment_id
      left join shipment_route_segment srs on srs.shipment_id = s.shipment_id
      left join shipment_package_route_seg sprs on sprs.shipment_id = srs.shipment_id
      and sprs.shipment_route_segment_id = srs.shipment_route_segment_id
      left join postal_address dpa on srs.DEST_CONTACT_MECH_ID = dpa.CONTACT_MECH_ID
    where
      (
        s.status_id = "SHIPMENT_SHIPPED"
        or s.shipment_id is null
      )
      and oi.quantity = 1
      and os.status_datetime = (
        select
          max(mos.status_datetime)
        from
          order_status mos
        where
          mos.order_id = os.order_id
          and mos.order_item_seq_id = os.order_item_seq_id
          and mos.status_id = "ITEM_COMPLETED"
      )
    order by
      os.created_tx_stamp
  ) temp

-- ******************************************************************
-- SQL to fetch the remaining data, mainly status dates (Completed order)
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
      os.status_id = "ITEM_COMPLETED"
      and (
        os.created_tx_stamp between '${min_cursor}' and '${max_cursor}'
      )
  ),
  ranked_order_facility_change as (
    select
      ofc.order_id,
      ofc.order_item_seq_id,
      ofc.change_datetime,
      ofc.comments,
      row_number() over (
        partition by
          ofc.order_id,
          ofc.order_item_seq_id
        order by
          ofc.change_datetime desc
      ) rn
    from
      order_facility_change ofc
    where
      ofc.change_reason_enum_id = "BROKERED"
  )
select
  os.order_id AS `ORDER_ID`,
  os.order_item_seq_id AS `ORDER_ITEM_SEQ_ID`,
  os.status_datetime AS `ITEM_COMPLETED_DATE`,
  date(os.status_datetime) AS `ITEM_COMPLETED_DATE_DIM_ID`,
  rofc.change_datetime AS `BROKERED_DATE`,
  rofc.comments AS `BROKERED_COMMENTS`,
  s.shipment_id AS `SHIPMENT_ID`,
  (
    select
      max(osd.status_datetime)
    from
      order_status osd
    where
      osd.order_id = os1.order_id
      and osd.order_item_seq_id = os.order_item_seq_id
      and osd.status_id = "ITEM_CREATED"
  ) AS `ITEM_CREATED_DATE`,
  (
    select
      max(osd.status_datetime)
    from
      order_status osd
    where
      osd.order_id = os1.order_id
      and osd.order_item_seq_id = os.order_item_seq_id
      and osd.status_id = "ITEM_APPROVED"
  ) AS `ITEM_APPROVED_DATE`,
  (
    select
      max(osd.status_date)
    from
      shipment_status osd
    where
      osd.shipment_id = os1.shipment_id
      and osd.status_id = "SHIPMENT_INPUT"
  ) AS `SHIPMENT_INPUT_DATE`,
  (
    select
      max(osd.status_date)
    from
      shipment_status osd
    where
      osd.shipment_id = os1.shipment_id
      and osd.status_id = "SHIPMENT_PACKED"
  ) AS `SHIPMENT_PACKED_DATE`,
  (
    select
      max(osd.status_date)
    from
      shipment_status osd
    where
      osd.shipment_id = os1.shipment_id
      and osd.status_id = "SHIPMENT_SHIPPED"
  ) AS `SHIPMENT_SHIPPED_DATE`
from
  order_status_slice os
  left join order_shipment os1 on os1.order_id = os.order_id
  and os1.order_item_seq_id = os.order_item_seq_id
  left join shipment s on s.shipment_id = os1.shipment_id
  left join ranked_order_facility_change rofc on rofc.order_id = os.order_id
  and rofc.order_item_seq_id = os.order_item_seq_id
  and rofc.rn = 1
where (s.shipment_type_id = "SALES_SHIPMENT" and s.status_id = "SHIPMENT_SHIPPED") or s.shipment_id is null


-- ******************************************************************
-- Base Query that fetches initial data (Cancelled order)
-- ******************************************************************
select
  *,
  date(ITEM_CANCELLED_DATE) as ITEM_CANCELLED_DATE_DIM_ID
from
  (
    select
      oh.ORDER_ID AS `ORDER_ID`,
      oh.status_id AS `ORDER_STATUS`,
      oi.ORDER_ITEM_SEQ_ID AS `ORDER_ITEM_SEQ_ID`,
      oh.EXTERNAL_ID AS `EXTERNAL_ID`,
      oi.EXTERNAL_ID AS `ITEM_EXTERNAL_ID`,
      oh.ORDER_NAME AS `ORDER_NAME`,
      oh.ORDER_TYPE_ID AS `ORDER_TYPE_ID`,
      oh.PRODUCT_STORE_ID AS `PRODUCT_STORE_ID`,
      oh.SALES_CHANNEL_ENUM_ID AS `SALES_CHANNEL_ENUM_ID`,
      oh.ENTRY_DATE AS `ENTRY_DATE`,
      oh.ORDER_DATE AS `ORDER_DATE`,
      date(oh.ORDER_DATE) AS `ORDER_DATE_DIM_ID`,
      (
        select
          sum(oa.amount)
        from
          order_adjustment oa
        where
          oa.order_id = oh.order_id
          and oa.order_adjustment_type_id in ("SHIPPING_CHARGES", "SHIPPING_SALES_TAX", "EXT_SHIP_ADJUSTMENT")
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
      oisg.CREATED_STAMP AS `SHIP_GROUP_CREATED_STAMP`,
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
      oh.ORIGIN_FACILITY_ID AS `ORIGIN_FACILITY_ID`,
      srs.DEST_FACILITY_ID AS `DEST_FACILITY_ID`,
      srs.ACTUAL_CARRIER_CODE AS `ACTUAL_CARRIER_CODE`,
      srs.ACTUAL_COST AS `ACTUAL_COST`,
      (
        select
          sum(AMOUNT)
        from
          order_adjustment oa
        where
          oa.order_id = oi.order_id
          and oa.order_item_seq_id = oi.order_item_seq_id
          and oa.order_adjustment_type_id in ("EXT_PROMO_ADJUSTMENT")
      ) AS `ITEM_DISC_PER_UNIT`,
      (
        select
          sum(AMOUNT)
        from
          order_adjustment oa
        where
          oa.order_id = oi.order_id
          and oa.order_item_seq_id = oi.order_item_seq_id
          and oa.order_adjustment_type_id = "SALES_TAX"
      ) AS `ITEM_TAX_AMOUNT`,
      oh.PRIORITY AS `PRIORITY`,
      date_format(os.created_tx_stamp, "%Y-%m-%d %H:%i:%s.%f") AS `cursorDateStrFormatted`,
      os.created_tx_stamp cursorDate
    from
      order_item oi
      join order_status os on os.order_id = oi.order_id
      and oi.order_item_seq_id = os.order_item_seq_id
      and os.status_id = "ITEM_CANCELLED"
      join order_header oh on oh.order_id = oi.order_id
      and oh.ORDER_TYPE_ID = "SALES_ORDER"
      left join order_item_ship_group oisg on oisg.order_id = oi.order_id
      and oisg.SHIP_GROUP_SEQ_ID = oi.SHIP_GROUP_SEQ_ID
      left join order_shipment os1 on os1.order_id = oi.order_id
      and os1.order_item_seq_id = oi.order_item_seq_id
      and os1.ship_group_seq_id = oisg.ship_group_seq_id
      left join shipment s on s.shipment_id = os1.shipment_id
      left join shipment_route_segment srs on srs.shipment_id = s.shipment_id
      left join postal_address dpa on srs.DEST_CONTACT_MECH_ID = dpa.CONTACT_MECH_ID
    where
      (
        s.status_id <> "SHIPMENT_SHIPPED"
        or s.shipment_id is null
      )
      and oi.quantity = 1
      and os.status_datetime = (
        select
          max(mos.status_datetime)
        from
          order_status mos
        where
          mos.order_id = os.order_id
          and mos.order_item_seq_id = os.order_item_seq_id
          and mos.status_id = "ITEM_CANCELLED"
      )
  ) temp

-- ******************************************************************
-- SQL to fetch the remaining data, mainly status dates (Cancelled order)
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
      os.status_id = "ITEM_CANCELLED"
  ),
  ranked_order_facility_change as (
    select
      ofc.order_id,
      ofc.order_item_seq_id,
      ofc.change_datetime,
      ofc.comments,
      row_number() over (
        partition by
          ofc.order_id,
          ofc.order_item_seq_id
        order by
          ofc.change_datetime desc
      ) rn
    from
      order_facility_change ofc
    where
      ofc.change_reason_enum_id = "BROKERED"
  )
select
  os.order_id AS `ORDER_ID`,
  os.order_item_seq_id AS `ORDER_ITEM_SEQ_ID`,
  os.status_datetime AS `ITEM_CANCELLED_DATE`,
  date(os.status_datetime) AS `ITEM_CANCELLED_DATE_DIM_ID`,
  rofc.change_datetime AS `BROKERED_DATE`,
  rofc.comments AS `BROKERED_COMMENTS`,
  s.shipment_id AS `SHIPMENT_ID`,
  (
    select
      max(osd.status_datetime)
    from
      order_status osd
    where
      osd.order_id = os1.order_id
      and osd.order_item_seq_id = os.order_item_seq_id
      and osd.status_id = "ITEM_CREATED"
  ) AS `ITEM_CREATED_DATE`,
  (
    select
      max(osd.status_datetime)
    from
      order_status osd
    where
      osd.order_id = os1.order_id
      and osd.order_item_seq_id = os.order_item_seq_id
      and osd.status_id = "ITEM_APPROVED"
  ) AS `ITEM_APPROVED_DATE`,
  (
    select
      max(osd.status_date)
    from
      shipment_status osd
    where
      osd.shipment_id = os1.shipment_id
      and osd.status_id = "SHIPMENT_INPUT"
  ) AS `SHIPMENT_INPUT_DATE`,
  (
    select
      max(osd.status_date)
    from
      shipment_status osd
    where
      osd.shipment_id = os1.shipment_id
      and osd.status_id = "SHIPMENT_PACKED"
  ) AS `SHIPMENT_PACKED_DATE`,
  NULL AS `SHIPMENT_SHIPPED_DATE`
from
  order_status_slice os
  left join order_shipment os1 on os1.order_id = os.order_id
  and os1.order_item_seq_id = os.order_item_seq_id
  left join shipment s on s.shipment_id = os1.shipment_id
  left join ranked_order_facility_change rofc on rofc.order_id = os.order_id
  and rofc.order_item_seq_id = os.order_item_seq_id
  and rofc.rn = 1
where (s.shipment_type_id = "SALES_SHIPMENT" and s.status_id <> "SHIPMENT_SHIPPED") or s.shipment_id is null

-- ******************************************************************
-- Query to combine whole data
-- ******************************************************************

SELECT o.*, e.* 
FROM original o
LEFT JOIN enrichment e
ON o.ORDER_ID = e.ORDER_ID
and o.ORDER_ITEM_SEQ_ID = e.ORDER_ITEM_SEQ_ID
and o.SHIPMENT_ID = e.SHIPMENT_ID