-- PROCEDURE: get_sales_inventory_changes

DROP PROCEDURE IF EXISTS `get_sales_inventory_changes`;

delimiter //

CREATE PROCEDURE `get_sales_inventory_changes`(
    IN `start_timestamp_` DATETIME,
    IN `stop_timestamp_` DATETIME
)
BEGIN
    SELECT
-- NOTES(dustin): For debugging.
--
--        `sfs`.`entity_id` `order_id`,
--        `sfs`.`created_at`,
--        `sfsi`.`name`,
        `sfsi`.`sku`,
        `sfsi`.`qty` `quantity`
    FROM
        `sales_flat_shipment` `sfs`
    INNER JOIN `sales_flat_shipment_item` `sfsi` ON
        `sfsi`.`parent_id` = `sfs`.`entity_id`
    WHERE
        `sfs`.`created_at` BETWEEN `start_timestamp_` AND `stop_timestamp_`
    ORDER BY
        `sfs`.`created_at`;
END//

delimiter ;

-- PROCEDURE: get_sales_with_times

DROP PROCEDURE IF EXISTS `get_sales_with_times`;

delimiter //

CREATE PROCEDURE `get_sales_with_times`(IN `date_from` DATETIME, IN `date_to` DATETIME)
BEGIN

SELECT 
  sales.entity_id AS order_id,
  sales.created_at,
  sales.increment_id AS order_number,
  sales.customer_id,
  sales_items.sku, 
  sales_items.product_id, 
  sales_items.qty_ordered AS quantity,
  COALESCE(att_style.value, '') AS style_code
FROM sales_flat_order AS sales
 INNER JOIN sales_flat_order_item AS sales_items ON sales.entity_id = sales_items.order_id
 LEFT OUTER JOIN (SELECT item.entity_id AS product_id, 
                         item.value
                   FROM catalog_product_entity_varchar AS item 
                     INNER JOIN eav_attribute AS att ON item.attribute_id = att.attribute_id 
                      WHERE att.attribute_code = 'style') AS att_style ON att_style.product_id = sales_items.product_id
WHERE 
    sales.created_at >= date_from AND (date_to IS NULL OR sales.created_at < date_to) AND
    sales_items.product_type = 'simple' AND 
    sales.`status` NOT IN ('canceled', 'fraud', 'holded', 'paypal_canceled_reversal', 'paypal_reversed', 'pending_payment', 'pending_paypal')

ORDER BY order_id
;

END//

delimiter ;

-- PROCEDURE: get_sales_with_start_order_id

DROP PROCEDURE IF EXISTS `get_sales_with_start_order_id`;

delimiter //

CREATE PROCEDURE `get_sales_with_start_order_id`(IN `start_order_id` INT UNSIGNED)
BEGIN

SELECT 
  sales.entity_id AS order_id,
  sales.increment_id AS order_number,
  sales.created_at,
  sales.customer_id,
  sales_items.sku, 
  sales_items.product_id, 
  sales_items.qty_ordered AS quantity,
  COALESCE(att_style.value, '') AS style_code
FROM sales_flat_order AS sales
 INNER JOIN sales_flat_order_item AS sales_items ON sales.entity_id = sales_items.order_id
 LEFT OUTER JOIN (SELECT item.entity_id AS product_id, 
                         item.value
                   FROM catalog_product_entity_varchar AS item 
                     INNER JOIN eav_attribute AS att ON item.attribute_id = att.attribute_id 
                      WHERE att.attribute_code = 'style') AS att_style ON att_style.product_id = sales_items.product_id
WHERE 
    sales.entity_id >= start_order_id AND
    sales_items.product_type = 'simple' AND 
    sales.`status` NOT IN ('canceled', 'fraud', 'holded', 'paypal_canceled_reversal', 'paypal_reversed', 'pending_payment', 'pending_paypal')

ORDER BY order_id
;

END//

delimiter ;
