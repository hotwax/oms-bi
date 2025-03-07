-- ******************************************************************
-- Base Query that fetches initial data
-- ******************************************************************
select
  *,
  date_format(itemCompletedDate, "%Y-%m-%d") as itemCompletedDateDimId
from
  (
    select
      oh.ORDER_ID AS `orderId`,
      oi.ORDER_ITEM_SEQ_ID AS `orderItemSeqId`,
      oh.EXTERNAL_ID AS `externalId`,
      oi.EXTERNAL_ID AS `itemExternalId`,
      oh.ORDER_NAME AS `orderName`,
      oh.ORDER_TYPE_ID AS `orderTypeId`,
      oh.PRODUCT_STORE_ID AS `productStoreId`,
      oh.SALES_CHANNEL_ENUM_ID AS `salesChannelEnumId`,
      date_format(oh.ENTRY_DATE, "%Y-%m-%d %H:%i:%s") AS `entryDate`,
      date_format(oh.ORDER_DATE, "%Y-%m-%d %H:%i:%s") AS `orderDate`,
      (
        select
          sum(oa.amount)
        from
          order_adjustment oa
        where
          oa.order_id = oh.order_id
          and oa.order_adjustment_type_id in ("SHIPPING_CHARGES", "SHIPPING_SALES_TAX", "EXT_SHIP_ADJUSTMENT")
      ) AS `shippingCharges`,
      oi.PRODUCT_ID AS `productId`,
      oi.ITEM_DESCRIPTION AS `itemDescription`,
      oi.QUANTITY AS `quantity`,
      oi.CANCEL_QUANTITY AS `cancelQuantity`,
      oi.UNIT_PRICE AS `unitPrice`,
      oi.STATUS_ID AS `itemStatusId`,
      date_format(os.status_datetime, "%Y-%m-%d %H:%i:%s") AS `itemCompletedDate`,
      os.status_user_login AS `fulfilledByUserLoginId`,
      oisg.SHIPMENT_METHOD_TYPE_ID AS `shipmentMethodTypeId`,
      date_format(oisg.CREATED_STAMP, "%Y-%m-%d %H:%i:%s") AS `shipGroupCreatedStamp`,
      oisg.FACILITY_ID AS `facilityId`,
      dpa.CONTACT_MECH_ID AS `destContactMechId`,
      dpa.STATE_PROVINCE_GEO_ID AS `destStateProvinceGeoId`,
      dpa.CITY AS `destCity`,
      dpa.ADDRESS1 AS `destAddress1`,
      dpa.POSTAL_CODE AS `destPostalCode`,
      dpa.LATITUDE AS `destLatitude`,
      dpa.LONGITUDE AS `destLongitude`,
      srs.TRACKING_ID_NUMBER AS `trackingIdNumber`,
      s.SHIPMENT_ID AS `shipmentId`,
      oh.ORIGIN_FACILITY_ID AS `orderOriginFacilityId`,
      srs.ORIGIN_FACILITY_ID AS `originFacilityId`,
      srs.DEST_FACILITY_ID AS `destFacilityId`,
      srs.ACTUAL_CARRIER_CODE AS `actualCarrierCode`,
      srs.ACTUAL_COST AS `actualCost`,
      (
        select
          sum(AMOUNT)
        from
          order_adjustment oa
        where
          oa.order_id = oi.order_id
          and oa.order_item_seq_id = oi.order_item_seq_id
          and oa.order_adjustment_type_id in ("EXT_PROMO_ADJUSTMENT")
      ) AS `itemDiscPerUnit`,
      (
        select
          sum(AMOUNT)
        from
          order_adjustment oa
        where
          oa.order_id = oi.order_id
          and oa.order_item_seq_id = oi.order_item_seq_id
          and oa.order_adjustment_type_id = "SALES_TAX"
      ) AS `itemTaxAmount`,
      oh.PRIORITY AS `priority`,
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
-- SQL to fetch the remaining data, mainly status dates
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
    os.order_id orderId,
    os.order_item_seq_id orderItemSeqId,
    DATE_FORMAT(os.status_datetime, "%Y-%m-%d %H:%i:%s") itemCompletedDate,
    DATE_FORMAT(rofc.change_datetime, "%Y-%m-%d %H:%i:%s") brokeredDate,
    s.shipment_id shipmentId,
    DATE_FORMAT(
        (
            select
                max(osd.status_datetime)
            from
                order_status osd
            where
                osd.order_id = os1.order_id
                and osd.order_item_seq_id = os.order_item_seq_id
                and osd.status_id = "ITEM_CREATED"
        ),
        "%Y-%m-%d %H:%i:%s"
    ) itemCreatedDate,
    DATE_FORMAT(
        (
            select
                max(osd.status_datetime)
            from
                order_status osd
            where
                osd.order_id = os1.order_id
                and osd.order_item_seq_id = os.order_item_seq_id
                and osd.status_id = "ITEM_APPROVED"
        ),
        "%Y-%m-%d %H:%i:%s"
    ) itemApprovedDate,
    DATE_FORMAT(
        (
            select
                max(osd.status_date)
            from
                shipment_status osd
            where
                osd.shipment_id = os1.shipment_id
                and osd.status_id = "SHIPMENT_INPUT"
        ),
        "%Y-%m-%d %H:%i:%s"
    ) shipmentInputDate,
    DATE_FORMAT(
        (
            select
                max(osd.status_date)
            from
                shipment_status osd
            where
                osd.shipment_id = os1.shipment_id
                and osd.status_id = "SHIPMENT_PACKED"
        ),
        "%Y-%m-%d %H:%i:%s"
    ) shipmentPackedDate,
    DATE_FORMAT(
        (
            select
                max(osd.status_date)
            from
                shipment_status osd
            where
                osd.shipment_id = os1.shipment_id
                and osd.status_id = "SHIPMENT_SHIPPED"
        ),
        "%Y-%m-%d %H:%i:%s"
    ) shipmentShippedDate
from
    order_status_slice os
    left join order_shipment os1 on os1.order_id = os.order_id
    and os1.order_item_seq_id = os.order_item_seq_id
    left join shipment s on s.shipment_id = os1.shipment_id
    left join ranked_order_facility_change rofc on rofc.order_id = os.order_id
    and rofc.order_item_seq_id = os.order_item_seq_id
    and rofc.rn = 1
where (s.shipment_type_id = "SALES_SHIPMENT" and s.status_id = "SHIPMENT_SHIPPED") or s.shipment_id is null