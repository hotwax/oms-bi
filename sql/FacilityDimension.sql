-- ******************************************************************
-- Query that fetched Facility dimension fields
-- ******************************************************************

select
    f.FACILITY_ID AS `FACILITY_ID`,
    f.FACILITY_NAME AS `FACILITY_NAME`,
    f.FACILITY_TYPE_ID AS `FACILITY_TYPE_ID`,
    ft.PARENT_TYPE_ID AS `PARENT_TYPE_ID`,
    pa.LATITUDE AS `LATITUDE`,
    pa.LONGITUDE AS `LONGITUDE`,
    pa.CITY AS `CITY`,
    pa.STATE_PROVINCE_GEO_ID AS `STATE_PROVINCE_GEO_ID`,
    pa.COUNTRY_GEO_ID AS `COUNTRY_GEO_ID`,
    pa.POSTAL_CODE AS `POSTAL_CODE`,
    pa.ADDRESS1 AS `ADDRESS1`,
    f.CREATED_TX_STAMP AS 'cursorDate'
from
    facility f
    join facility_type ft on ft.FACILITY_TYPE_ID = f.FACILITY_TYPE_ID
    left join facility_contact_mech_purpose fcmp on fcmp.facility_id = f.facility_id
    and fcmp.contact_mech_purpose_type_id = "PRIMARY_LOCATION"
    and (
        fcmp.THRU_DATE is null
        or fcmp.THRU_DATE > now()
    )
    left join postal_address pa on pa.contact_mech_id = fcmp.contact_mech_id