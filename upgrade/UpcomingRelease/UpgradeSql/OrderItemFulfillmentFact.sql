-- ******************************************************************
-- Query to add orderDateDimId to orderItemFulfillmentFact
-- ******************************************************************

ALTER TABLE order_item_fulfillment_fact
ADD COLUMN order_date_dim_id DATE;


-- ******************************************************************
-- Query to insert data into orderDateDimId in orderItemFulfillmentFact
-- ******************************************************************

UPDATE order_item_fulfillment_fact OIFF
SET OIFF.order_date_dim_id = DATE(OIFF.order_date) WHERE OIFF.order_date_dim_id IS NULL;

-- ******************************************************************
-- Query to add indexes to orderItemFulfillmentFact
-- ******************************************************************

CREATE INDEX IDX_OIFF_PRODUCT_ID ON order_item_fulfillment_fact (product_id);
CREATE INDEX IDX_OIFF_ORDER_DATE ON order_item_fulfillment_fact (order_date_dim_id);
CREATE INDEX IDX_OIFF_FACILITY_ID ON order_item_fulfillment_fact (facility_id);
CREATE INDEX IDX_OIFF_SALES_CHANNEL ON order_item_fulfillment_fact (sales_channel_enum_id);
CREATE INDEX IDX_OIFF_SHIP_METHOD ON order_item_fulfillment_fact (shipment_method_type_id);
CREATE INDEX IDX_OIFF_ORDER_DATE_DIM_ID ON order_item_fulfillment_fact (order_date_dim_id);
CREATE INDEX IDX_OIFF_ITEM_COMPLETED_DIM_ID ON order_item_fulfillment_fact (item_completed_date_dim_id);
CREATE INDEX IDX_OIFF_ITEM_CANCELLED_DIM_ID ON order_item_fulfillment_fact (item_cancelled_date_dim_id);
CREATE INDEX IDX_OIFF_ODATE_SC_SHIP ON order_item_fulfillment_fact (order_date_dim_id,sales_channel_enum_id,shipment_method_type_id);