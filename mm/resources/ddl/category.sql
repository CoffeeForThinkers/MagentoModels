-- PROCEDURE: get_sales_inventory_changes

DROP PROCEDURE IF EXISTS `get_category_listing`;

delimiter //

CREATE PROCEDURE `get_category_listing`(
    IN `store_id` INT

)
BEGIN

SELECT
   C.entity_id AS id,
   C.entity_type_id,
   C.attribute_set_id,
   C.parent_id,
   C.position,
   C.level,
   CCEI.value AS is_active,
   CCEV.store_id,
   CCEV.value AS name
FROM catalog_category_entity C
  INNER JOIN eav_entity_type EAVT ON C.entity_type_id = EAVT.entity_type_id
  INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id
                 FROM catalog_category_entity_varchar CEV
                    INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
                                                       EAV.attribute_code = 'name' AND
                                                       (CEV.store_id = store_id OR store_id IS NULL))
                               AS CCEV ON C.entity_id = CCEV.entity_id
  INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
                 FROM catalog_category_entity_int CEI
                    INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
                                                       EAV.attribute_code = 'is_active' AND
                                                       (CEI.store_id = store_id OR store_id IS NULL))
                               AS CCEI ON C.entity_id = CCEI.entity_id
WHERE EAVT.entity_type_code = 'catalog_category'
;

END//

delimiter ;
