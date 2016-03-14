-- PROCEDURE: get_stock

DROP PROCEDURE IF EXISTS `get_stock`;

delimiter //

CREATE PROCEDURE `get_stock`(
    IN `sku` VARCHAR(64)
)
BEGIN
    SELECT `prd`.`entity_id` as product_id, 
           `prd`.`sku`, 
             `stk`.`qty`,
             `stk`.`is_in_stock`
    FROM `cataloginventory_stock_item` `stk`
    INNER JOIN `catalog_product_entity` `prd` ON `stk`.`product_id` = `prd`.`entity_id`
    WHERE (`prd`.`sku` = sku OR sku IS NULL);
END

delimiter ;
