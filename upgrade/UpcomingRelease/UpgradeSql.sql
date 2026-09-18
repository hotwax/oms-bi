-- ******************************************************************
-- Query to add Columns to returnItemFact
-- ******************************************************************

ALTER TABLE return_item_fact
ADD COLUMN SHPFI_REFUND_DISCREP DECIMAL(24, 4);

ALTER TABLE return_item_fact
ADD COLUMN SHPFI_CUSTOMER DECIMAL(24, 4);

ALTER TABLE return_item_fact
ADD COLUMN SHPFI_DAMAGE DECIMAL(24, 4);

ALTER TABLE return_item_fact
ADD COLUMN SHPFI_BALANCING_ADJ DECIMAL(24, 4);

ALTER TABLE return_item_fact
ADD COLUMN SHPFI_PEND_REF_DISC DECIMAL(24, 4);

ALTER TABLE return_item_fact
ADD COLUMN SHPFI_RESTOCK DECIMAL(24, 4);