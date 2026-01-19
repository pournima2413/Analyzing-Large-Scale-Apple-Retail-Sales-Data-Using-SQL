DROP TABLE IF EXISTS category;
CREATE TABLE category(
	category_id VARCHAR(10) PRIMARY KEY,
	category_name VARCHAR(25)
)

DROP TABLE IF EXISTS products;
CREATE TABLE products(
	product_id VARCHAR(10) PRIMARY KEY,
	product_name VARCHAR(35),
	category_id VARCHAR(10),
	launch_date DATE,
	price FLOAT,
	CONSTRAINT fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
)

DROP TABLE IF EXISTS stores;
CREATE TABLE stores(
	store_id VARCHAR(10) PRIMARY KEY,
	store_name VARCHAR(25),
	city VARCHAR(25),
	country VARCHAR(25)
)

ALTER TABLE stores
ALTER COLUMN store_name TYPE varchar(50);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
	 sale_id VARCHAR(15) PRIMARY KEY,
	 sale_date DATE,
	 store_id VARCHAR(10),
	 product_id VARCHAR(10),
	 quantity INT,
	 CONSTRAINT fk_store FOREIGN KEY(store_id) REFERENCES stores(store_id),
	 CONSTRAINT fk_product FOREIGN KEY(product_id) REFERENCES products(product_id)
	 
)

DROP TABLE IF EXISTS warranty;
CREATE TABLE warranty(
	claim_id VARCHAR(10) PRIMARY KEY,
	clain_date DATE,
	
	sale_id varchar(15),
	repair_status VARCHAR(15),
	CONSTRAINT fk_orders FOREIGN KEY(sale_id) REFERENCES sales(sale_id)
)

SELECT 'Schema Created Successfully' as Success_message;

SELECT * FROM sales;
SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM stores;
SELECT * FROM warranty;