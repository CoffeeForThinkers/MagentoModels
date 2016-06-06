-- PROCEDURE: get_product_from_image

DROP PROCEDURE IF EXISTS `get_product_from_image`;

delimiter //

CREATE PROCEDURE `get_product_from_image`(
    IN `image_file` VARCHAR(255)
)
BEGIN

SELECT E.entity_id AS product_id,
       GV.store_id,
       E.entity_type_id,
       E.type_id,
       E.sku,
       E.attribute_set_id,
       G.attribute_id,
       G.value AS image_path,
       GV.position,
       GV.disabled
FROM catalog_product_entity_media_gallery G
 INNER JOIN catalog_product_entity_media_gallery_value GV ON G.value_id = GV.value_id
 INNER JOIN catalog_product_entity E ON E.entity_id = G.entity_id
WHERE LOWER(TRIM(GV.`label`)) = LOWER(TRIM(image_file))
;

END//

delimiter ;
