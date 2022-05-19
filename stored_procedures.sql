USE `library`;


-- SP order books by

DROP procedure IF EXISTS `order_books_by`;

DELIMITER $$
USE `library`$$
CREATE PROCEDURE `order_books_by` (IN column_to_order_by VARCHAR(30), IN order_way VARCHAR(4))
-- Order book table by column_to_order_by parameter. 
-- order_way = ASC/DESC
-- Example:
-- CALL order_books_by("id_publisher", "ASC");
BEGIN
	IF column_to_order_by <> "" THEN
		SET @order_query = CONCAT_WS(" ", "ORDER BY", column_to_order_by, order_way); -- query order by
	ELSE
		SET @order_query = "";
	END IF;
    SET @result_query = CONCAT_WS(" ", "SELECT * FROM book", @order_query);
    PREPARE result_statement FROM @result_query;
    EXECUTE result_statement; -- executes result_statement query
    DEALLOCATE PREPARE result_statement; -- deallocates
END$$

DELIMITER ;


-- SP insert or delete book category

DROP procedure IF EXISTS `insert_or_delete_book_category`;

DELIMITER $$
USE `library`$$
CREATE PROCEDURE `insert_or_delete_book_category` (
	IN statement_in VARCHAR(6),
	IN id_category tinyint,
	IN id_book tinyint)
-- Insert or delete an id_book-id_category match from book_category table depending on `statement_in`
-- Examples:
-- CALL insert_or_delete_book_category("DELETE", 1, 1);
-- CALL insert_or_delete_book_category("INSERT", 2, 2);
proc_label: BEGIN
	IF UPPER(statement_in) LIKE "DELETE" THEN
		-- DELETE STATEMENT
		SET @result_query = CONCAT_WS(" ", "DELETE FROM book_category WHERE id_category =", id_category, "AND id_book =", id_book);
	ELSEIF UPPER(statement_in) LIKE "INSERT" THEN
		-- INSERT STATEMENT
		SET @result_query = CONCAT_WS(" ", "INSERT INTO book_category VALUES (", id_category, ",", id_book, ")");
	ELSE
		-- NULL STATEMENT
		LEAVE proc_label;
	END IF;

    PREPARE result_statement FROM @result_query;
    EXECUTE result_statement; -- executes result_statement query
    DEALLOCATE PREPARE result_statement; -- deallocates
END$$

DELIMITER ;


-- SP insert book category

DROP procedure IF EXISTS `insert_book_category`;

DELIMITER $$
USE `library`$$
CREATE PROCEDURE `insert_book_category` (
	IN id_category tinyint,
	IN id_book tinyint)
-- Inserts an id_book-id_category match from book_category table (using SP `insert_or_delete_book_category`)
-- Example:
-- CALL insert_book_category(1, 1);
BEGIN
    CALL insert_or_delete_book_category("INSERT", id_category, id_book); -- Call SP with "INSERT" argument
END$$

DELIMITER ;


-- SP delete book category

DROP procedure IF EXISTS `delete_book_category`;

DELIMITER $$
USE `library`$$
CREATE PROCEDURE `delete_book_category` (
	IN id_category tinyint,
	IN id_book tinyint)
-- Deletes an id_book-id_category match from book_category table (using SP `insert_or_delete_book_category`)
-- Example:
-- CALL delete_book_category(1, 1);
BEGIN
    CALL insert_or_delete_book_category("DELETE", id_category, id_book); -- Call SP with "DELETE" argument
END$$


-- SP update book_status in book_inventory table
DROP procedure IF EXISTS `update_book_status`;

DELIMITER $$
USE `library`$$
CREATE PROCEDURE `update_book_status` (
	IN id_book_inventory_argument tinyint unsigned,
	IN id_book_status_argument tinyint unsigned)
BEGIN
    UPDATE book_inventory
    SET id_book_status = id_book_status_argument
    WHERE id_book_inventory = id_book_inventory_argument;
END$$


-- SP update book_status in book_inventory table, depending id_book_return from book_return table. This SP uses update_book_status SP.
DROP procedure IF EXISTS `update_book_status_from_id_book_return`;

DELIMITER $$
USE `library`$$
CREATE PROCEDURE `update_book_status_from_id_book_return` (
	IN id_book_return_argument tinyint unsigned,
	IN id_book_status_argument tinyint unsigned)
BEGIN
	SET @id_book_inventory_to_update = (
        SELECT l.id_book_inventory
        FROM loan AS l
		INNER JOIN book_return AS br
			ON l.id_loan = br.id_loan
		WHERE br.id_book_return = id_book_return_argument
    );

    CALL update_book_status(
		@id_book_inventory_to_update,
		id_book_status_argument
	);
END$$