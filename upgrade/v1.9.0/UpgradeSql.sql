-- ******************************************************************
-- Query to Update dataType for externalReturnId in ReturnItemFact
-- ******************************************************************
ALTER TABLE return_item_fact
MODIFY COLUMN external_return_id VARCHAR(63);