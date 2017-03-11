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

-- PROCEDURE: get_sales_and_customer_info_with_times

DROP PROCEDURE IF EXISTS `get_sales_and_customer_info_with_times`;

delimiter //

CREATE PROCEDURE `get_sales_and_customer_info_with_times`(
    IN `date_from` DATETIME,
    IN `date_to` DATETIME
  )
BEGIN

DECLARE tz VARCHAR(50) DEFAULT NULL;


SELECT value INTO tz FROM core_config_data WHERE path = 'general/locale/timezone' AND scope = 'default' LIMIT 1;
IF tz IS NULL THEN
    SET tz = 'GMT';
END IF;

# Temporary table to aggregate items per order.
# Unsure why Magento creates multiple entries per sku per order
DROP TEMPORARY TABLE IF EXISTS tmpOrders;
CREATE TEMPORARY TABLE tmpOrders AS
(
    SELECT
      sales.entity_id         AS order_id,
      sales_items.product_id  AS product_id,
      MIN(sales_items.sku)    AS sku,
      MAX(COALESCE(sales_price.price, sales_items.price)) AS price,
      SUM(sales_items.qty_ordered) AS quantity,
      MIN(sales.increment_id) AS order_number,
      MIN(sales.customer_id)  AS customer_id,
      MIN(sales.shipping_description) AS shipping_method,
      MIN(CONVERT_TZ(sales.created_at, 'GMT', tz)) AS created_at
    FROM sales_flat_order AS sales
     INNER JOIN sales_flat_order_item AS sales_items ON sales.entity_id = sales_items.order_id AND  sales_items.product_type = 'simple'
     LEFT OUTER JOIN (SELECT
         sales_price.order_id,
         sales_price.sku,
         MAX(sales_price.price) AS price
       FROM sales_flat_order_item  AS sales_price
         WHERE sales_price.product_type = 'configurable'
       GROUP BY sales_price.order_id, sales_price.sku) AS sales_price ON sales_items.order_id = sales_price.order_id AND sales_price.sku = sales_items.sku
    WHERE
        sales.created_at >= date_from AND (date_to IS NULL OR sales.created_at < date_to) AND
        sales_items.product_type = 'simple' AND
        sales.`status` NOT IN ('canceled', 'fraud', 'holded', 'paypal_canceled_reversal', 'paypal_reversed', 'pending_payment', 'pending_paypal')
    GROUP BY sales.entity_id, sales_items.product_id
    ORDER BY sales.entity_id, sales_items.product_id
);


SELECT
  sales.order_id,
  sales.created_at,
  sales.order_number,
  sales.customer_id,
  sales.sku,
  sales.product_id,
  sales.quantity,
  sales.price,
  COALESCE(att_style.value, '') AS style_code,
  address.firstname,
  COALESCE(address.middlename, '') AS middlename,
  sales.shipping_method,
  address.lastname,
  address.street,
  address.city,
  address.region,
  address.postcode,
  address.country_id AS country,
  COALESCE(address.email, '') AS email,
  address.telephone
FROM tmpOrders AS sales
 INNER JOIN sales_flat_order_address AS address  ON sales.order_id = address.parent_id AND address.address_type = 'shipping'
 LEFT OUTER JOIN (SELECT item.entity_id AS product_id,
                         item.value
                   FROM catalog_product_entity_varchar AS item
                     INNER JOIN eav_attribute AS att ON item.attribute_id = att.attribute_id
                      WHERE att.attribute_code = 'style') AS att_style ON att_style.product_id = sales.product_id
ORDER BY order_id
;

END//

delimiter ;

-- PROCEDURE: get_sales_and_customer_info_with_start_order_id

DROP PROCEDURE IF EXISTS `get_sales_and_customer_info_with_start_order_id`;

delimiter //

CREATE PROCEDURE `get_sales_and_customer_info_with_start_order_id`(
    IN `start_order_id` INT UNSIGNED
)
BEGIN

DECLARE tz VARCHAR(50) DEFAULT NULL;


SELECT value INTO tz FROM core_config_data WHERE path = 'general/locale/timezone' AND scope = 'default' LIMIT 1;
IF tz IS NULL THEN
    SET tz = 'GMT';
END IF;

# Temporary table to aggregate items per order.
# Unsure why Magento creates multiple entries per sku per order
DROP TEMPORARY TABLE IF EXISTS tmpOrders;
CREATE TEMPORARY TABLE tmpOrders AS
(
    SELECT
      sales.entity_id         AS order_id,
      sales_items.product_id  AS product_id,
      MIN(sales_items.sku)    AS sku,
      MAX(COALESCE(sales_price.price, sales_items.price)) AS price,
      SUM(sales_items.qty_ordered) AS quantity,
      MIN(sales.increment_id) AS order_number,
      MIN(sales.customer_id)  AS customer_id,
      MIN(sales.shipping_description) AS shipping_method,
      MIN(CONVERT_TZ(sales.created_at, 'GMT', tz)) AS created_at
    FROM sales_flat_order AS sales
     INNER JOIN sales_flat_order_item AS sales_items ON sales.entity_id = sales_items.order_id AND  sales_items.product_type = 'simple'
     LEFT OUTER JOIN (SELECT
         sales_price.order_id,
         sales_price.sku,
         MAX(sales_price.price) AS price
       FROM sales_flat_order_item  AS sales_price
         WHERE sales_price.product_type = 'configurable'
       GROUP BY sales_price.order_id, sales_price.sku) AS sales_price ON sales_items.order_id = sales_price.order_id AND sales_price.sku = sales_items.sku
    WHERE
        sales.entity_id >= start_order_id AND
        sales_items.product_type = 'simple' AND
        sales.`status` NOT IN ('canceled', 'fraud', 'holded', 'paypal_canceled_reversal', 'paypal_reversed', 'pending_payment', 'pending_paypal')
    GROUP BY sales.entity_id, sales_items.product_id
    ORDER BY sales.entity_id, sales_items.product_id
);


SELECT
  sales.order_id,
  sales.created_at,
  sales.order_number,
  sales.customer_id,
  sales.sku,
  sales.product_id,
  sales.quantity,
  sales.price,
  COALESCE(att_style.value, '') AS style_code,
  address.firstname,
  COALESCE(address.middlename, '') AS middlename,
  sales.shipping_method,
  address.lastname,
  address.street,
  address.city,
  address.region,
  address.postcode,
  address.country_id AS country,
  COALESCE(address.email, '') AS email,
  address.telephone
FROM tmpOrders AS sales
 INNER JOIN sales_flat_order_address AS address  ON sales.order_id = address.parent_id AND address.address_type = 'shipping'
 LEFT OUTER JOIN (SELECT item.entity_id AS product_id,
                         item.value
                   FROM catalog_product_entity_varchar AS item
                     INNER JOIN eav_attribute AS att ON item.attribute_id = att.attribute_id
                      WHERE att.attribute_code = 'style') AS att_style ON att_style.product_id = sales.product_id
ORDER BY order_id
;

END//

delimiter ;
