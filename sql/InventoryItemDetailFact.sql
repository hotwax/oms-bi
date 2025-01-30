SELECT 
  IID.Inventory_Item_Id,
  IID.Inventory_Item_Detail_Seq_Id,
  II.Facility_Id,
  II.Product_Id,
  PAC.Average_Cost_Post_Event, -- Entity needs to be added back after db merge
  IID.Effective_Date,
  IID.Quantity_On_Hand_Diff,
  IID.Available_To_Promise_Diff,
  IID.QOH_Before_Diff, -- Field needs to be added into the IID table
  IID.ATP_Before_Diff, -- Field needs to be added into the IID table
  IID.Reason_Enum_Id,
  IID.Order_Id,
  IID.Order_Item_Seq_Id,
  IID.Ship_Group_Seq_Id,
  IID.Shipment_Id,
  IID.Shipment_Item_Seq_Id,
  IID.Return_Id,	
  IID.Return_Item_Seq_Id,
  IID.Item_Issuance_Id,
  IID.Receipt_Id
FROM 
  inventory_item_detail IID 
JOIN 
  inventory_item II
  ON IID.inventory_item_id = II.inventory_item_id
JOIN
  product_average_cost PAC
  ON II.product_id = PAC.product_id
  AND II.facility_id = PAC.facility_id
  AND PAC.product_average_cost_type_id = 'WEIGHTED_AVG_COST'