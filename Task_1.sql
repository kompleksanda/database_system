--A

DROP TABLE IF EXISTS Bank, Customer, Store, Transactions, Product, WarehouseItem;
DROP TYPE IF EXISTS ENUM_PRODUCT_TYPE;

CREATE TYPE ENUM_PRODUCT_TYPE AS ENUM ('INSTRUMENT', 'MEDIA');

CREATE TABLE Bank (
    bank_id BIGSERIAL NOT NULL PRIMARY KEY CHECK (bank_id >= 0),
    bank_name VARCHAR(50) NOT NULL,
    bank_address VARCHAR(100) NOT NULL,
    sort_code CHAR(6) NOT NULL
);

INSERT INTO Bank (bank_name, bank_address, sort_code)
          VALUES ('First Bank', 'Brooklyn', '124546'),
                 ('Chase Bank', 'Manhattan', '087363'),
                 ('BOA', 'Queens', '783733'),
                 ('Greendot', 'Lagos', '345677'),
                 ('UBA', 'Accra', '143678'),
                 ('Duetche Bank', 'Frankfurt', '798343');


CREATE TABLE Customer (
    customer_id BIGSERIAL NOT NULL PRIMARY KEY CHECK (customer_id >= 0),
    surname VARCHAR(20) NOT NULL,
    firstname VARCHAR(20) NOT NULL,
    home_address VARCHAR(100) NOT NULL,
    bank_id BIGSERIAL,
    CONSTRAINT fk_bank_id
        FOREIGN KEY (bank_id)
        REFERENCES Bank(bank_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    account_number CHAR(10),
    phone_number VARCHAR(15),
    dob DATE CONSTRAINT DateBeforeNow
		CHECK (dob < current_date)
);

INSERT INTO Customer (surname, firstname, home_address, bank_id, account_number)
              VALUES ('Edward', 'Smith', 'Manhattan', 1, '0345736381'),
                     ('Jeremy', 'Houghtons', 'Queens', 3, '5467760381'),
                     ('Adewale', 'Iyanu', 'Lagos', 4, '0938348976'),
                     ('John', 'Percs', 'Accra', 6, '8732875683'),
                     ('Constance', 'Olawale', 'Frankfurt', 6, '5428976690'),
                     ('Alex', 'Stone', 'Brooklyn', 4, '2390287666'),
                     ('Idowu', 'Alaba', 'Lagos', 2, '0937839922');

CREATE TABLE Product (
    product_id BIGSERIAL NOT NULL PRIMARY KEY CHECK (product_id >= 0),
    product_cost DECIMAL NOT NULL,
    product_type ENUM_PRODUCT_TYPE NOT NULL,
    product_name VARCHAR(50) NOT NULL,
    product_description VARCHAR(150)
);

INSERT INTO Product (product_cost, product_type, product_name)
             VALUES (50, 'MEDIA', 'CD'),
                    (123, 'INSTRUMENT', 'Guitar'),
                    (87.3, 'INSTRUMENT', 'Piano'),
                    (34, 'MEDIA', 'Flash Drive'),
                    (20.67, 'MEDIA', 'Memory Card'),
                    (93, 'INSTRUMENT', 'Drum'),
                    (22, 'MEDIA', 'DVD'),
                    (45, 'INSTRUMENT', 'Mic'),
                    (112, 'MEDIA', 'Diskette'),
                    (134, 'INSTRUMENT', 'Amplifier'),
                    (50, 'MEDIA', 'SSD'),
                    (99, 'INSTRUMENT', 'Saxophone');

CREATE TABLE Store (
    store_id BIGSERIAL NOT NULL PRIMARY KEY CHECK (store_id >= 0),
    store_address VARCHAR(100) NOT NULL
);

INSERT INTO Store (store_address)
           VALUES ('Brooklyn'),
                  ('Queens'),
                  ('Lagos'),
                  ('Accra'),
                  ('Frankfurt'),
                  ('Manhattan');

CREATE TABLE WarehouseItem (
    store_id BIGSERIAL NOT NULL CHECK (store_id >= 0),
    CONSTRAINT fk_store_id
        FOREIGN KEY (store_id)
        REFERENCES Store(store_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    product_id BIGSERIAL NOT NULL CHECK (product_id >= 0),
    CONSTRAINT fk_product_id
        FOREIGN KEY (product_id)
        REFERENCES Product(product_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    PRIMARY KEY	(store_id, product_id)
);

INSERT INTO WarehouseItem (store_id, product_id)
                   VALUES (1, 8),
                          (2, 3),
                          (3, 4),
                          (4, 2),
                          (5, 7),
                          (6, 5),
                          (1, 1),
                          (2, 6),
                          (3, 9),
                          (4, 10),
                          (5, 11),
                          (6, 12);

CREATE TABLE Transactions (
    transaction_id BIGSERIAL NOT NULL PRIMARY KEY CHECK (transaction_id >= 0),
    customer_id BIGSERIAL NOT NULL CHECK (customer_id >= 0),
    CONSTRAINT fk_customer_id
        FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    store_id BIGSERIAL NOT NULL CHECK (store_id >= 0),
    CONSTRAINT fk_store_id
        FOREIGN KEY (store_id)
        REFERENCES Store(store_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    product_id BIGSERIAL NOT NULL CHECK (product_id >= 0),
    CONSTRAINT fk_product_id
        FOREIGN KEY (product_id)
        REFERENCES Product(product_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    transaction_date DATE NOT NULL
);

INSERT INTO Transactions (customer_id, store_id, product_id, transaction_date)
                  VALUES (1, 1, 8, '2020-10-20'),
                         (2, 4, 2, '2020-1-2'),
                         (3, 1, 1, '2022-6-20'),
                         (4, 2, 3, '2021-8-17'),
                         (5, 3, 9, '2019-12-12'),
                         (6, 4, 10, '2020-2-3');


-- B
CREATE OR REPLACE PROCEDURE registerNewCustomers (_surname VARCHAR, _firstname VARCHAR, _homeAddress VARCHAR,
    _bankID INTEGER, _accountNumber VARCHAR, _phoneNumber VARCHAR, _dob DATE)
AS $$
BEGIN
    INSERT INTO Customer (surname, firstname, home_address, bank_id, account_number, phone_number, dob)
    VALUES (_surname, _firstname, _homeAddress, _bankID, _account, _phoneNumber, _dob);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkYear() RETURNS trigger AS
$$
DECLARE _date DATE;
BEGIN
SELECT transaction_date INTO _date FROM Transactions
    WHERE transaction_id = NEW.transaction_id;
    IF _date <= current_date THEN
        RAISE EXCEPTION 'Transaction date must be in the future';
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER DateInFuture BEFORE INSERT ON Transactions
    FOR EACH ROW EXECUTE PROCEDURE checkYear();