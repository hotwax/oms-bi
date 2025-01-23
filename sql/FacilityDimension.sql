-- ******************************************************************
-- Query that fetched Facility dimension fields
-- ******************************************************************

select
    f.FACILITY_ID AS `facilityId`,
    f.FACILITY_NAME AS `facilityName`,
    f.FACILITY_TYPE_ID AS `facilityTypeId`,
    ft.PARENT_TYPE_ID AS `parentTypeId`,
    pa.LATITUDE AS `latitude`,
    pa.LONGITUDE AS `longitude`,
    pa.CITY AS `city`,
    pa.STATE_PROVINCE_GEO_ID AS `stateProvinceGeoId`,
    pa.COUNTRY_GEO_ID AS `countryGeoId`,
    pa.POSTAL_CODE AS `postalCode`,
    pa.ADDRESS1 AS `address1`,
    f.CREATED_TX_STAMP AS `cursorDate`
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