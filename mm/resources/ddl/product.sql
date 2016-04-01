-- PROCEDURE: update_enum_product_attribute

DROP PROCEDURE IF EXISTS `update_enum_product_attribute`;

delimiter //

CREATE PROCEDURE `update_enum_product_attribute`(
    IN `sku` VARCHAR(64), 
    IN `att_name` VARCHAR(255), 
    IN `att_value` INT
)
BEGIN

UPDATE catalog_product_entity_int AS attvalue
    INNER JOIN catalog_product_entity AS item   ON item.entity_id = attvalue.entity_id
    INNER JOIN eav_attribute AS att ON att.attribute_id = attvalue.attribute_id AND att.attribute_code = att_name
 SET 
   value = att_value
WHERE item.sku = sku;

  SELECT
    row_count() `affected`;
END//

delimiter ;
