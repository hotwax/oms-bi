-- ******************************************************************
-- Query to fetch the Product Dimension fields
-- ******************************************************************

SELECT
    P.PRODUCT_ID AS `productId`,
    P.PRODUCT_TYPE_ID AS `productTypeId`,
    PT.PARENT_TYPE_ID AS `parentTypeId`,
    P.INTERNAL_NAME AS `internalName`,
    (
        SELECT GI.ID_VALUE
        FROM GOOD_IDENTIFICATION GI
        WHERE
            GI.PRODUCT_ID = P.PRODUCT_ID
            AND GI.GOOD_IDENTIFICATION_TYPE_ID = 'SKU'
        LIMIT 1
    ) AS `sku`,
    (
        SELECT GI.ID_VALUE
        FROM GOOD_IDENTIFICATION GI
        WHERE
            GI.PRODUCT_ID = P.PRODUCT_ID
            AND GI.GOOD_IDENTIFICATION_TYPE_ID = 'UPCA'
        LIMIT 1
    ) AS `upca`,
    P.PRODUCT_NAME AS `productName`,
    P.BRAND_NAME AS `brandName`,
    p2.PRODUCT_ID AS `parentProductId`,
    p2.PRODUCT_NAME AS `parentProductName`,
    pc.PRODUCT_CATEGORY_ID AS `primaryProductCategoryId`,
    pc.CATEGORY_NAME AS `primaryProductCategoryName`,
    product_feat.color AS `featureColor`,
    product_feat.size AS `featureSize`,
    (
        case
            when p.IS_VIRTUAL = 'N'
            and p.is_variant = 'N' then "Standard"
            when p.IS_VIRTUAL = 'N'
            and p.is_variant = 'Y' then "Variant"
            when p.IS_VIRTUAL = 'Y'
            and p.is_variant = 'N' then "Virtual"
            when p.IS_VIRTUAL = 'Y'
            and p.is_variant = 'Y' then "Both"
            else null
        end
    ) AS `variationType`,
    P.CREATED_TX_STAMP AS 'cursorDate'
FROM
    PRODUCT P
    JOIN PRODUCT_TYPE PT ON PT.PRODUCT_TYPE_ID = P.PRODUCT_TYPE_ID
    LEFT JOIN product_category pc on pc.product_category_id = p.PRIMARY_PRODUCT_CATEGORY_ID
    left join product_assoc pa on pa.PRODUCT_ID_TO = p.PRODUCT_ID
    and pa.PRODUCT_ASSOC_TYPE_ID = "PRODUCT_VARIANT"
    and pa.from_date = (
        select max(pa2.from_date)
        from product_assoc pa2
        where
            pa2.product_id_to = p.product_id
            and pa2.PRODUCT_ASSOC_TYPE_ID = "PRODUCT_VARIANT"
    )
    left join product p2 on pa.PRODUCT_ID = p2.PRODUCT_ID
    left join (
        select PRODUCT_ID, min(
                CASE
                    WHEN pf.PRODUCT_FEATURE_TYPE_ID = 'COLOR' then pf.DESCRIPTION
                end
            ) as 'color', min(
                CASE
                    WHEN pf.PRODUCT_FEATURE_TYPE_ID = 'SIZE' then pf.DESCRIPTION
                end
            ) as 'size'
        from
            product_feature_appl pfa
            join product_feature pf on pf.PRODUCT_FEATURE_ID = pfa.PRODUCT_FEATURE_ID
            and pf.PRODUCT_FEATURE_TYPE_ID in ('SIZE', 'COLOR')
            and pfa.PRODUCT_FEATURE_APPL_TYPE_ID = "STANDARD_FEATURE"
        group by
            PRODUCT_ID
    ) product_feat on product_feat.PRODUCT_ID = p.PRODUCT_ID