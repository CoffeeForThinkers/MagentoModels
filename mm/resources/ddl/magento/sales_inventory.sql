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
