CREATE DATABASE grocery;
USE grocery;

-- Create `uom` Table
CREATE TABLE uom (
    uom_id INT PRIMARY KEY NOT NULL,
    uom_name VARCHAR(255)
);

INSERT INTO uom (uom_id, uom_name)
VALUES 
    (1, 'kilogram'),
    (2, 'litre'),
    (3, 'piece'),
    (4, 'dozen');

-- Create `orders` Table
CREATE TABLE orders (
    order_id INT NOT NULL,
    customer_name VARCHAR(255),
    total DECIMAL(8,2),
    order_datetime DATETIME,
    PRIMARY KEY (order_id)
);

INSERT INTO orders (order_id, customer_name, total, order_datetime)
VALUES 
    (1, 'suyash', 280, '2012-12-12'),
    (2, 'john doe', 180, '2024-11-17'),
    (3, 'jace', 30000, '2024-11-17');

-- Create `products` Table
CREATE TABLE products (
    product_id INT NOT NULL UNIQUE,
    name VARCHAR(255),
    uom_id INT,
    price_per_unit DECIMAL(8,2),
    PRIMARY KEY (product_id),
    FOREIGN KEY (uom_id) REFERENCES uom(uom_id)
);

INSERT INTO products (product_id, name, uom_id, price_per_unit)
VALUES
    (1, 'rice', 1, 50),
    (2, 'milk', 2, 40),
    (3, 'soap', 3, 30),
    (4, 'sugar', 1, 60),
    (5, 'CrazyDiscoverer', 3, 10000);

-- Create `order_details` Table
CREATE TABLE order_details (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT,
    total_price DECIMAL(8,2),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO order_details (order_id, product_id, quantity, total_price)
VALUES 
    (1, 1, 2, 100),
    (2, 3, 6, 180),
    (3, 5, 3, 300000);

-- Create `payment` Table
CREATE TABLE payment (
    payment_id INT PRIMARY KEY NOT NULL,
    order_id INT NOT NULL,
    payment_method VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

INSERT INTO payment (payment_id, order_id, payment_method)
VALUES 
    (1, 1, 'online'),
    (2, 2, 'online'),
    (3, 3, 'cash');


--to update total price in order_details
DELIMITER //

CREATE TRIGGER update_total_price
BEFORE INSERT ON order_details
FOR EACH ROW
BEGIN
    DECLARE unit_price DECIMAL(8,2);

    -- Fetch the unit price from the products table
    SELECT price_per_unit INTO unit_price
    FROM products
    WHERE product_id = NEW.product_id;

    -- Calculate the total price
    SET NEW.total_price = unit_price * NEW.quantity;
END;

//

DELIMITER ;

--prevent deletion of orders based on active payments

DELIMITER //

CREATE TRIGGER prevent_order_deletion
BEFORE DELETE ON orders
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM payment WHERE order_id = OLD.order_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete an order with associated payments.';
    END IF;
END;

//

DELIMITER ;

-- to update or insert order_details 
DELIMITER //

CREATE TRIGGER update_order_total_after_insert
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    DECLARE order_total DECIMAL(8,2);

    -- Calculate the new total for the order
    SELECT SUM(total_price) INTO order_total
    FROM order_details
    WHERE order_id = NEW.order_id;

    -- Update the total in the orders table
    UPDATE orders
    SET total = order_total
    WHERE order_id = NEW.order_id;
END;

//

DELIMITER ;


-- to view order_summary
CREATE VIEW order_summary AS
SELECT 
    o.order_id,
    o.customer_name,
    SUM(od.total_price) AS total_order_amount
FROM 
    orders o
JOIN 
    order_details od ON o.order_id = od.order_id
GROUP BY 
    o.order_id, o.customer_name;

-- to view product sales 
CREATE VIEW product_sales AS
SELECT 
    p.product_id,
    p.name AS product_name,
    SUM(od.quantity) AS total_quantity_sold,
    SUM(od.total_price) AS total_sales
FROM 
    products p
JOIN 
    order_details od ON p.product_id = od.product_id
GROUP BY 
    p.product_id, p.name;
