-- ******************************************************************
-- Query to add effectiveDateDimId to inventoryItemDetailFact
-- ******************************************************************

ALTER TABLE inventory_item_detail_fact
ADD COLUMN effective_date_dim_id DATE;

-- ******************************************************************
-- Query to insert data into effectiveDateDimId in inventoryItemDetailFact
-- ******************************************************************

UPDATE inventory_item_detail_fact IIDF
SET IIDF.effective_date_dim_id = DATE(IIDF.effective_date) WHERE IIDF.effective_date_dim_id IS NULL; 

-- ******************************************************************
-- Query to add indexes to inventoryItemDetailFact
-- ******************************************************************

CREATE INDEX IDX_IIDF_EFFECTIVE_DATE ON inventory_item_detail_fact (effective_date);
CREATE INDEX IDX_IIDF_EFFECTIVE_DATE_DIM_ID ON inventory_item_detail_fact (effective_date_dim_id);
CREATE INDEX IDX_IIDF_REASON_ENUM_ID ON inventory_item_detail_fact (reason_enum_id);
CREATE INDEX IDX_IIDF_FACILITY_ID ON inventory_item_detail_fact (facility_id);
CREATE INDEX IDX_IIDF_PRODUCT_ID ON inventory_item_detail_fact (product_id);


-- ******************************************************************
-- Query to add indexes to orderFacilityChangeFact
-- ******************************************************************
CREATE INDEX IDX_OFCH_ORDER_ID ON order_facility_change_fact (order_id);
CREATE INDEX IDX_OFCH_ORDER_ITEM ON order_facility_change_fact (order_id,order_item_seq_id);
CREATE INDEX IDX_OFCH_ORDER_ITEM_FACILITY ON order_facility_change_fact (order_id, order_item_seq_id, facility_id);
CREATE INDEX IDX_OFCH_FACILITY_ID ON order_facility_change_fact (facility_id);
CREATE INDEX IDX_OFCH_SHIPMENT_METHOD_TYPE_ID ON order_facility_change_fact (shipment_method_type_id);
CREATE INDEX IDX_OFCH_FROM_FACILITY_ID ON order_facility_change_fact (from_facility_id);
CREATE INDEX IDX_OFCH_CHANGE_REASON_ENUM_ID ON order_facility_change_fact (change_reason_enum_id);
CREATE INDEX IDX_OFCH_PRODUCT_STORE_ID ON order_facility_change_fact (product_store_id);
CREATE INDEX IDX_OFCH_CHANGE_DATETIME ON order_facility_change_fact (change_datetime);
CREATE INDEX IDX_OFCH_ASSIGNMENT_ENUM_ID ON order_facility_change_fact (assignment_enum_id);    


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


-- ******************************************************************
-- Query to add indexes to AppeasementFact
-- ******************************************************************
CREATE INDEX IDX_AF_ORDER_ID ON appeasement_fact (order_id);
CREATE INDEX IDX_AF_ORDER_ITEM ON appeasement_fact (order_id, order_item_seq_id);
CREATE INDEX IDX_AF_ORDER_ITEM_FACILITY ON appeasement_fact (order_id, order_item_seq_id, facility_id);
CREATE INDEX IDX_AF_ORDER_ITEM_FACILITY_SHIPMENT_METHOD_TYPE ON appeasement_fact (order_id, order_item_seq_id, facility_id, shipment_method_type_id);
CREATE INDEX IDX_AF_ORDER_ITEM_FACILITY_SHIPMENT_METHOD_TYPE_CHANGE_REASON ON appeasement_fact (order_id, order_item_seq_id, facility_id, shipment_method_type_id, change_reason_enum_id);
CREATE INDEX IDX_AF_RETURN_CHANNEL_ENUM_ID ON appeasement_fact (return_channel_enum_id);
CREATE INDEX IDX_AF_RETURN_STATUS_ID ON appeasement_fact (return_status_id);
CREATE INDEX IDX_AF_SALES_CHANNEL_ENUM_ID ON appeasement_fact (sales_channel_enum_id);


-- ******************************************************************
-- Query to add indexes to ReturnItemFact
-- ******************************************************************
CREATE INDEX IDX_RIF_ORDER_ID ON return_item_fact (order_id);
CREATE INDEX IDX_RIF_ORDER_ITEM_FACILITY ON return_item_fact (order_id, order_item_seq_id, order_origin_facility_id);
CREATE INDEX IDX_RIF_SALES_CHANNEL_ENUM_ID ON return_item_fact (sales_channel_enum_id);
CREATE INDEX IDX_RIF_RETURN_STATUS_ID ON return_item_fact (return_status_id); 
CREATE INDEX IDX_RIF_PRODUCT_ID ON return_item_fact (product_id);
CREATE INDEX IDX_RIF_ORDER_ORIGIN_FACILITY_ID ON return_item_fact (order_origin_facility_id); 
CREATE INDEX IDX_RIF_DESTINATION_FACILITY_ID ON return_item_fact (destination_facility_id);



-- ******************************************************************
-- Query to add indexes to OrderAdjustmentFact
-- ******************************************************************
CREATE INDEX IDX_OAF_ORDER_ID ON order_adjustment_fact (order_id);
CREATE INDEX IDX_OAF_ORDER_ITEM ON order_adjustment_fact (order_id, order_item_seq_id);


-- ******************************************************************
-- Query to add columns to transferOrderItemFact 
-- ******************************************************************
ALTER TABLE transfer_order_item_fact
ADD COLUMN order_date_dim_id DATE,
ADD COLUMN order_entry_date_dim_id DATE,
ADD COLUMN order_completion_date_dim_id DATE,
ADD COLUMN order_cancellation_date_dim_id DATE,
ADD COLUMN order_item_creation_date_dim_id DATE,
ADD COLUMN order_item_completion_date_dim_id DATE,
ADD COLUMN order_item_cancellation_date_dim_id DATE;

-- ***********************************************************************
-- Query to insert data into Dimention columns in transferOrderItemFact
-- ***********************************************************************
UPDATE transfer_order_item_fact TOIF
SET TOIF.order_date_dim_id = DATE(TOIF.order_date) WHERE TOIF.order_date_dim_id IS NULL;

UPDATE transfer_order_item_fact TOIF
SET TOIF.order_entry_date_dim_id = DATE(TOIF.order_entry_date) WHERE TOIF.order_entry_date_dim_id IS NULL; 

UPDATE transfer_order_item_fact TOIF
SET TOIF.order_completion_date_dim_id = DATE(TOIF.order_completion_date) WHERE TOIF.order_completion_date_dim_id IS NULL;   

UPDATE transfer_order_item_fact TOIF
SET TOIF.order_cancellation_date_dim_id = DATE(TOIF.order_cancellation_date) WHERE TOIF.order_cancellation_date_dim_id IS NULL;

UPDATE transfer_order_item_fact TOIF
SET TOIF.order_item_creation_date_dim_id = DATE(TOIF.order_item_creation_date) WHERE TOIF.order_item_creation_date_dim_id IS NULL;  

UPDATE transfer_order_item_fact TOIF
SET TOIF.order_item_completion_date_dim_id = DATE(TOIF.order_item_completion_date) WHERE TOIF.order_item_completion_date_dim_id IS NULL;    

UPDATE transfer_order_item_fact TOIF
SET TOIF.order_item_cancellation_date_dim_id = DATE(TOIF.order_item_cancellation_date) WHERE TOIF.order_item_cancellation_date_dim_id IS NULL;  


-- ******************************************************************
-- Query to add indexes to transferOrderItemFact
-- ******************************************************************

CREATE INDEX IDX_TOIF_ORDER_DATE_DIM_ID ON transfer_order_item_fact (order_date_dim_id);
CREATE INDEX IDX_TOIF_ORDER_ENTRY_DATE_DIM_ID ON transfer_order_item_fact (order_entry_date_dim_id);
CREATE INDEX IDX_TOIF_ORDER_COMPLETION_DATE_DIM_ID ON transfer_order_item_fact (order_completion_date_dim_id);
CREATE INDEX IDX_TOIF_ORDER_CANCELLATION_DATE_DIM_ID ON transfer_order_item_fact (order_cancellation_date_dim_id);
CREATE INDEX IDX_TOIF_ORDER_ITEM_CREATION_DATE_DIM_ID ON transfer_order_item_fact (order_item_creation_date_dim_id);
CREATE INDEX IDX_TOIF_ORDER_ITEM_COMPLETION_DATE_DIM_ID ON transfer_order_item_fact (order_item_completion_date_dim_id);
CREATE INDEX IDX_TOIF_ORDER_ITEM_CANCELLATION_DATE_DIM_ID ON transfer_order_item_fact (order_item_cancellation_date_dim_id);    
CREATE INDEX IDX_TOIF_PRODUCT_ID ON transfer_order_item_fact (product_id);
CREATE INDEX IDX_TOIF_ORIGIN_FACILITY_ID ON transfer_order_item_fact (origin_facility_id);
CREATE INDEX IDX_TOIF_DESTINATION_FACILITY_ID ON transfer_order_item_fact (destination_facility_id);
CREATE INDEX IDX_TOIF_SALES_CHANNEL_ENUM_ID ON transfer_order_item_fact (sales_channel_enum_id);
CREATE INDEX IDX_TOIF_ORDER_DATE ON transfer_order_item_fact (order_date);
CREATE INDEX IDX_TOIF_SHIPMENT_ID ON transfer_order_item_fact (shipment_id);
CREATE INDEX IDX_TOIF_SHIPMENT_METHOD_TYPE_ID ON transfer_order_item_fact (requested_ship_meth_type_id);
CREATE INDEX IDX_TOIF_ORDER_ID ON transfer_order_item_fact (order_id);
CREATE INDEX IDX_TOIF_ORDER_ITEM ON transfer_order_item_fact (order_id, order_item_seq_id);


-- ******************************************************************
-- Query to add indexes to OrderSalesAgreement
-- ******************************************************************
CREATE INDEX IDX_OSA_ORDER_ID ON order_sales_agreement (order_id);
CREATE INDEX IDX_OSA_LINE_TYPE ON order_sales_agreement (line_type);


