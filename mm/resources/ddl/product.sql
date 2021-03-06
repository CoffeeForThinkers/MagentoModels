-- PROCEDURE: catalog_association

DROP PROCEDURE IF EXISTS `catalog_association`;

delimiter //

CREATE PROCEDURE `catalog_association`(
	IN `vproduct_id` INT,
	IN `vlink_product_id` INT,
	IN `vlink_type_id` SMALLINT,
	IN `vcleanup` TINYINT
)
BEGIN

IF vcleanup > 0 THEN
     DELETE FROM catalog_product_link
     WHERE product_id = vproduct_id AND link_type_id = vlink_type_id;
END IF;

 INSERT IGNORE INTO catalog_product_link
   (product_id, linked_product_id, link_type_id)
 VALUES
   (vproduct_id, vlink_product_id, vlink_type_id);

SELECT
    row_count() `affected`;

END//

delimiter ;

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

-- PROCEDURE: get_configurable_associated_products

DROP PROCEDURE IF EXISTS `get_configurable_associated_products`;

delimiter //

CREATE PROCEDURE `get_configurable_associated_products`(
    IN `store_id` INT,
    IN `is_active` TINYINT,
    IN `is_visible` TINYINT
)
BEGIN

# defaults for is_visible = NULL
DECLARE visibility_min INT DEFAULT 1;
DECLARE visibility_max INT DEFAULT 99;

# Magento uses 1 - True, 2 - False for Active status
IF is_active IS NOT NULL THEN
     SET is_active = IF(is_active = 0, 2, 1);
END IF;

SET visibility_min = IF(is_visible > 0, 2, visibility_min);
SET visibility_max = IF(is_visible = 0, 1, visibility_max);

SELECT
   S.link_id,
   S.product_id,
   S.parent_id,
   P.attribute_set_id,
   P.entity_type_id,
   P.type_id,
   P.sku,
   CCEV.value  AS name,
   CCEI1.value AS active,
   CCEI2.value AS visibility
FROM catalog_product_super_link S
 INNER JOIN catalog_product_entity P ON S.product_id = P.entity_id
 INNER JOIN eav_entity_type     EAVT ON P.entity_type_id = EAVT.entity_type_id
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id
              FROM catalog_product_entity_varchar CEV
                INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
                                                   EAV.attribute_code = 'name' AND
                                                   (CEV.store_id = store_id OR store_id IS NULL)) AS CCEV ON P.entity_id = CCEV.entity_id
 INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
              FROM catalog_product_entity_int CEI
                INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
                                                   EAV.attribute_code IN ('status') AND
                                                   (CEI.store_id = store_id OR store_id IS NULL)) AS CCEI1 ON P.entity_id = CCEI1.entity_id
 INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
              FROM catalog_product_entity_int CEI
                INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
                                                   EAV.attribute_code IN ('visibility') AND
                                                   (CEI.store_id = store_id OR store_id IS NULL)) AS CCEI2 ON P.entity_id = CCEI2.entity_id
WHERE EAVT.entity_type_code = 'catalog_product' AND
      (CCEI1.value = is_active OR is_active IS NULL) AND
      (CCEI2.value BETWEEN visibility_min AND visibility_max)
;

END//

delimiter ;

-- PROCEDURE: get_configurable_associated_products_stock

DROP PROCEDURE IF EXISTS `get_configurable_associated_products_stock`;

delimiter //

CREATE PROCEDURE `get_configurable_associated_products_stock`(
    IN `store_id` INT
)
BEGIN

SELECT
   S.link_id,
   S.product_id,
   S.parent_id,
   P.attribute_set_id,
   P.entity_type_id,
   P.type_id,
   PC.sku      AS parent_sku,
   P.sku,
   CCEV.value  AS name,
   CCEI1.value AS active,
   CCEI2.value AS parent_visibility,
   CCEP.value  AS primary_sku,
   CCEO.value  AS sort_item,
   CCES.value  AS style,
   CCEI3.value AS color_id,
   INV.qty,
   INV.is_in_stock
FROM catalog_product_super_link S
 INNER JOIN catalog_product_entity P ON S.product_id = P.entity_id
 INNER JOIN catalog_product_entity PC ON S.parent_id = PC.entity_id
 INNER JOIN eav_entity_type EAVT ON P.entity_type_id = EAVT.entity_type_id
 INNER JOIN cataloginventory_stock_item INV ON S.product_id = INV.product_id
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id
                 FROM catalog_product_entity_varchar CEV
                    INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
                                                        EAV.attribute_code = 'name' AND
                                                                    (CEV.store_id = store_id OR store_id IS NULL)) AS CCEV ON P.entity_id = CCEV.entity_id
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id
                 FROM catalog_product_entity_varchar CEV
                    INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
                                                        EAV.attribute_code = 'primary_sku' AND
                                                                    (CEV.store_id = store_id OR store_id IS NULL)) AS CCEP ON S.parent_id = CCEP.entity_id
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id, CP.sku
              FROM catalog_product_entity_varchar CEV
                INNER JOIN catalog_product_entity CP ON CEV.entity_id = CP.entity_id
                INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
                                                   EAV.attribute_code = 'sort_item' AND
                                                   (CEV.store_id = store_id OR store_id IS NULL)) AS CCEO ON CCEO.sku = CCEP.value
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id
                 FROM catalog_product_entity_varchar CEV
                    INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
                                                        EAV.attribute_code = 'style' AND
                                                                    (CEV.store_id = store_id OR store_id IS NULL)) AS CCES ON S.parent_id = CCES.entity_id
 INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
              FROM catalog_product_entity_int CEI
                INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
                                                        EAV.attribute_code IN ('status') AND
                                                                    (CEI.store_id = store_id OR store_id IS NULL)) AS CCEI1 ON P.entity_id = CCEI1.entity_id
 INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
              FROM catalog_product_entity_int CEI
                INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
                                                        EAV.attribute_code IN ('visibility') AND
                                                                    (CEI.store_id = store_id OR store_id IS NULL)) AS CCEI2 ON S.parent_id  = CCEI2.entity_id
 INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
              FROM catalog_product_entity_int CEI
                INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
                                                        EAV.attribute_code IN ('color') AND
                                                                    (CEI.store_id = store_id OR store_id IS NULL)) AS CCEI3 ON P.entity_id = CCEI3.entity_id
WHERE EAVT.entity_type_code = 'catalog_product' AND
      (CCEI1.value = 1) AND (CCEI2.value = 4)
ORDER BY S.parent_id, CCEI3.value, INV.is_in_stock DESC, INV.qty DESC
;


END//

delimiter ;

-- PROCEDURE: upsert_product_int_attribute

DROP PROCEDURE IF EXISTS `upsert_product_int_attribute`;

delimiter //

CREATE PROCEDURE `upsert_product_int_attribute`(
    IN `sku` VARCHAR(64),
    IN `att_name` VARCHAR(255),
    IN `att_value` INT,
    IN `store_id` INT

)
BEGIN

DECLARE att_id  INT;
DECLARE prod_id  INT;
DECLARE entity_type_id INT;

SELECT I.attribute_id, P.entity_id, P.entity_type_id INTO att_id, prod_id, entity_type_id
 FROM catalog_product_entity_int I
   INNER JOIN eav_attribute A ON I.attribute_id = A.attribute_id
   INNER JOIN catalog_product_entity P ON I.entity_id = P.entity_id
WHERE P.sku = sku AND
      A.attribute_code = att_name AND
      I.store_id = store_id
LIMIT 1;

IF (att_id IS NOT NULL) THEN
    UPDATE catalog_product_entity_int I
    SET I.value = att_value
    WHERE I.entity_id = prod_id AND
          I.attribute_id = att_id;
ELSE
   SELECT A.attribute_id INTO att_id FROM eav_attribute A WHERE A.attribute_code = att_name;

   IF (att_id IS NOT NULL) THEN
       INSERT INTO catalog_product_entity_int
        (entity_type_id, attribute_id, store_id, entity_id, value)
        SELECT P.entity_type_id, att_id, store_id, P.entity_id, att_value
          FROM catalog_product_entity P
        WHERE P.sku = sku;
    END IF;
END IF;

SELECT
   row_count() 'affected';

END//

-- PROCEDURE: upsert_product_varchar_attribute

DROP PROCEDURE IF EXISTS `upsert_product_varchar_attribute`;

delimiter //

CREATE PROCEDURE `upsert_product_varchar_attribute`(
    IN `sku` VARCHAR(64),
    IN `att_name` VARCHAR(255),
    IN `att_value` VARCHAR(255),
    IN `store_id` INT
)
BEGIN

DECLARE att_id  INT;
DECLARE prod_id  INT;
DECLARE entity_type_id INT;

SELECT V.attribute_id, P.entity_id, P.entity_type_id INTO  att_id, prod_id, entity_type_id
 FROM catalog_product_entity_varchar V
   INNER JOIN eav_attribute A ON V.attribute_id = A.attribute_id
   INNER JOIN catalog_product_entity P ON V.entity_id = P.entity_id
WHERE P.sku = sku AND
      A.attribute_code = att_name AND
      V.store_id = store_id
LIMIT 1;

IF (att_id IS NOT NULL) THEN
    UPDATE catalog_product_entity_varchar V
    SET V.value = att_value
    WHERE V.entity_id = prod_id AND
          V.attribute_id = att_id;
ELSE
   SELECT A.attribute_id INTO att_id FROM  eav_attribute A WHERE A.attribute_code = att_name;

   IF (att_id IS NOT NULL) THEN
       INSERT INTO catalog_product_entity_varchar
        (entity_type_id, attribute_id, store_id, entity_id, value)
        SELECT P.entity_type_id, att_id, store_id, P.entity_id, att_value
          FROM catalog_product_entity P
        WHERE P.sku = sku;
    END IF;
END IF;

SELECT
   row_count() 'affected';

END//

-- PROCEDURE: upsert_product_price

DROP PROCEDURE IF EXISTS `upsert_product_price`;

delimiter //

CREATE PROCEDURE `upsert_product_price`(
    IN `sku` VARCHAR(300),
    IN `store_id` INT,
    IN `currency_code` VARCHAR(3),
    IN `price` DECIMAL(10,2),
    IN `special_price` DECIMAL(10,2)
)
BEGIN

IF EXISTS(SELECT 1 FROM catalog_price_list P
          WHERE P.sku = sku AND P.store_id = store_id AND P.currency_code = currency_code) THEN
BEGIN
    UPDATE catalog_price_list p
    SET p.price = price,
        p.special_price = special_price
    WHERE p.sku = sku AND p.store_id = store_id AND p.currency_code = UPPER(currency_code);
END;
ELSE
BEGIN
    INSERT INTO catalog_price_list (sku, store_id, currency_code, price, special_price)
    VALUES (sku, store_id, UPPER(currency_code), price, special_price);
END;
END IF;

 SELECT
    row_count() `affected`;

END//

-- PROCEDURE: get_product_listing_with_attributes

DROP PROCEDURE IF EXISTS `get_product_listing_with_attributes`;

delimiter //

CREATE PROCEDURE `get_product_listing_with_attributes`(
	IN `product_type` VARCHAR(50),
    IN `store_id` INT
)
BEGIN

SELECT
   P.entity_id AS product_id,
   P.attribute_set_id,
   P.entity_type_id,
   P.type_id,
   P.sku,
   CCEV.value  AS name,
   CCEI1.value AS active,
   CCEI2.value AS visibility,
   CCEO.value  AS sort_item,
   CCES.value  AS style
FROM catalog_product_entity P
 INNER JOIN eav_entity_type EAVT ON P.entity_type_id = EAVT.entity_type_id
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id
			     FROM catalog_product_entity_varchar CEV
    			    INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
					                                    EAV.attribute_code = 'name' AND
																	(CEV.store_id = store_id OR store_id IS NULL)) AS CCEV ON P.entity_id = CCEV.entity_id
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id, CP.sku
              FROM catalog_product_entity_varchar CEV
                INNER JOIN catalog_product_entity CP ON CEV.entity_id = CP.entity_id
                INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
                                                   EAV.attribute_code = 'sort_item' AND
                                                   (CEV.store_id = store_id OR store_id IS NULL)) AS CCEO ON P.sku = CCEO.sku
 INNER JOIN (SELECT CEV.entity_id, CEV.value, CEV.store_id
			     FROM catalog_product_entity_varchar CEV
    			    INNER JOIN eav_attribute AS EAV ON CEV.attribute_id = EAV.attribute_id AND
					                                    EAV.attribute_code = 'style' AND
																	(CEV.store_id = store_id OR store_id IS NULL)) AS CCES ON P.entity_id = CCES.entity_id
 INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
              FROM catalog_product_entity_int CEI
                INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
					                                    EAV.attribute_code IN ('status') AND
																	(CEI.store_id = store_id OR store_id IS NULL)) AS CCEI1 ON P.entity_id = CCEI1.entity_id
 INNER JOIN (SELECT CEI.entity_id, CEI.value, CEI.store_id
              FROM catalog_product_entity_int CEI
                INNER JOIN eav_attribute AS EAV ON CEI.attribute_id = EAV.attribute_id AND
					                                    EAV.attribute_code IN ('visibility') AND
																	(CEI.store_id = store_id OR store_id IS NULL)) AS CCEI2 ON P.entity_id = CCEI2.entity_id
WHERE EAVT.entity_type_code = 'catalog_product' AND
      (P.type_id = product_type OR product_type IS NULL)
;

END//