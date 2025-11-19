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