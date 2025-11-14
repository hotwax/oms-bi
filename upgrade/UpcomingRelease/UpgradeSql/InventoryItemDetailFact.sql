-- ******************************************************************
-- Query to add effectiveDateDimId to inventoryItemDetailFact
-- ******************************************************************

ALTER TABLE inventory_item_detail_fact
ADD COLUMN effective_date_dim_id DATE;


-- ******************************************************************
-- Query to add indexes to inventoryItemDetailFact
-- ******************************************************************

CREATE INDEX IDX_IIDF_EFFECTIVE_DATE ON inventory_item_detail_fact (effective_date);
CREATE INDEX IDX_IIDF_EFFECTIVE_DATE_DIM_ID ON inventory_item_detail_fact (effective_date_dim_id);
CREATE INDEX IDX_IIDF_REASON_ENUM_ID ON inventory_item_detail_fact (reason_enum_id);
CREATE INDEX IDX_IIDF_FACILITY_ID ON inventory_item_detail_fact (facility_id);
CREATE INDEX IDX_IIDF_PRODUCT_ID ON inventory_item_detail_fact (product_id);