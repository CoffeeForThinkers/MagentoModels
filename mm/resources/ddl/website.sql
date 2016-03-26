-- PROCEDURE: get_websites

DROP PROCEDURE IF EXISTS `get_websites`;

delimiter //

CREATE PROCEDURE `get_websites`(
)
BEGIN
    SELECT
        `cw`.`website_id`,
        `cw`.`name`
    FROM
        `core_website` `cw`
    ORDER BY
        `cw`.`sort_order`,
        `cw`.`name`;
END//

delimiter ;

-- PROCEDURE: get_default_website

DROP PROCEDURE IF EXISTS `get_default_website`;

delimiter //

CREATE PROCEDURE `get_default_website`(
)
BEGIN
    SELECT
        `cw`.`website_id`,
        `cw`.`name`
    FROM
        `core_website` `cw`
    WHERE
        `cw`.`is_default` = 1
    ORDER BY
        `cw`.`website_id`
    LIMIT 1;
END//

delimiter ;
