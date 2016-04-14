-- PROCEDURE: add_attribute_option

DROP PROCEDURE IF EXISTS `add_attribute_option`;

DELIMITER //

CREATE PROCEDURE `add_attribute_option`(IN `att_name` VARCHAR(255), IN `att_value` VARCHAR(255), IN `store_id` SMALLINT)
BEGIN

DECLARE att_id INT;
DECLARE result INT DEFAULT 0;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    SELECT 0 AS 'affected';
END;

-- Get Attribute Id
SELECT A.attribute_id INTO att_id
FROM eav_attribute A
  INNER JOIN eav_entity_type T ON A.entity_type_id = T.entity_type_id
WHERE T.entity_type_code = 'catalog_product' AND
      A.attribute_code = att_name AND
      A.backend_type = 'int'
LIMIT 1;

-- Check if the attribute option exists
IF NOT EXISTS (SELECT 1 = 1
        FROM eav_attribute_option AO
            INNER JOIN eav_attribute_option_value AV ON AO.option_id = AV.option_id
         WHERE AO.attribute_id = att_id AND
            TRIM(LOWER(AV.value)) = TRIM(LOWER(att_value)) AND
             AV.store_id = store_id) THEN
BEGIN
    START TRANSACTION;
        INSERT INTO eav_attribute_option (attribute_id, sort_order)
        VALUES (att_id, 0);

        INSERT INTO eav_attribute_option_value (option_id, store_id, value)
        VALUES (LAST_INSERT_ID(), store_id, TRIM(att_value));

        SET result = row_count();
    COMMIT;
END;
END IF;

SELECT
    result AS 'affected';

END//
DELIMITER ;

-- PROCEDURE: get_attribute_options

DROP PROCEDURE IF EXISTS `get_attribute_options`;

DELIMITER //
CREATE PROCEDURE `get_attribute_options`(IN `att_name` VARCHAR(255), IN `store_id` SMALLINT)
BEGIN

DECLARE att_id INT;

-- Get Attribute Id
SELECT A.attribute_id INTO att_id
FROM eav_attribute A
  INNER JOIN eav_entity_type T ON A.entity_type_id = T.entity_type_id
WHERE T.entity_type_code = 'catalog_product' AND
      A.attribute_code = att_name AND
      A.backend_type = 'int'
LIMIT 1;

SELECT AV.option_id, AV.value, AO.sort_order
  FROM eav_attribute_option AO
    INNER JOIN eav_attribute_option_value AV ON AO.option_id = AV.option_id
WHERE AO.attribute_id = att_id AND
      AV.store_id = store_id
ORDER BY AO.sort_order, AV.value;

END//
DELIMITER ;
