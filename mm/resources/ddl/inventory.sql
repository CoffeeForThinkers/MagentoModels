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

-- PROCEDURE: update_stock

DROP PROCEDURE IF EXISTS `update_stock`;

DELIMITER //

CREATE PROCEDURE `update_stock`(IN `sku` VARCHAR(64), IN `stock` DECIMAL(12,4), IN `force_in_stock` TINYINT(1))
BEGIN

   UPDATE `cataloginventory_stock_item` `stk`
      INNER JOIN `catalog_product_entity` `prd` ON `stk`.`product_id` = `prd`.`entity_id`
    SET 
        `stk`.`qty` = stock, 
       `stk`.`is_in_stock` = CASE WHEN (stock > 0 OR force_in_stock > 0) THEN 1 ELSE 0 END, 
       `stk`.`manage_stock` = 1,
       `stk`.`use_config_manage_stock` = 1,
       `stk`.`use_config_backorders` = 1,
       `stk`.`use_config_qty_increments` = 1, 
       `stk`.`use_config_enable_qty_inc` = 1,    
       `stk`.`use_config_min_sale_qty` = 1,
       `stk`.`use_config_min_qty` = 1
   WHERE `prd`.`sku` = sku;

   SELECT
      row_count() 'affected';
END//

DELIMITER ;
