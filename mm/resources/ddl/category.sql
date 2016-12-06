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

-- PROCEDURE: upsert_category_int_attribute

DROP PROCEDURE IF EXISTS `upsert_category_int_attribute`;

delimiter //

CREATE PROCEDURE `upsert_category_int_attribute`(
    IN `category_id` INT,
    IN `att_name` VARCHAR(255),
    IN `att_value` INT,
    IN `store_id` INT
)
BEGIN

DECLARE att_id  INT;
DECLARE cat_id  INT;
DECLARE entity_type_id INT;

SELECT I.attribute_id, C.entity_id, C.entity_type_id INTO att_id, cat_id, entity_type_id
 FROM catalog_category_entity_int I
   INNER JOIN eav_attribute A ON I.attribute_id = A.attribute_id
   INNER JOIN catalog_category_entity C ON I.entity_id = C.entity_id
WHERE C.entity_id = category_id AND
      A.attribute_code = att_name AND
      I.store_id = store_id
LIMIT 1;

IF (att_id IS NOT NULL) THEN
    UPDATE catalog_category_entity_int I
    SET I.value = att_value
    WHERE I.entity_id = cat_id AND
          I.attribute_id = att_id;
ELSE
   SELECT A.attribute_id INTO att_id FROM eav_attribute A WHERE A.attribute_code = att_name;

   IF (att_id IS NOT NULL) THEN
       INSERT INTO catalog_category_entity_int
        (entity_type_id, attribute_id, store_id, entity_id, value)
        SELECT C.entity_type_id, att_id, store_id, C.entity_id, att_value
          FROM catalog_category_entity C
        WHERE C.entity_id = category_id;
    END IF;
END IF;

SELECT
   row_count() 'affected';

END//
