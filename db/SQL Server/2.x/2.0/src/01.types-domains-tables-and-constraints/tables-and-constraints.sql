﻿EXECUTE dbo.drop_schema 'sales';
GO
CREATE SCHEMA sales;
GO


--TODO: CREATE UNIQUE INDEXES

CREATE TABLE sales.gift_cards
(
    gift_card_id                            integer IDENTITY PRIMARY KEY,
    gift_card_number                        national character varying(100) NOT NULL,
    payable_account_id                        integer NOT NULL REFERENCES finance.accounts,
    customer_id                             integer REFERENCES inventory.customers,
    first_name                              national character varying(100),
    middle_name                             national character varying(100),
    last_name                               national character varying(100),
    address_line_1                          national character varying(128),   
    address_line_2                          national character varying(128),
    street                                  national character varying(100),
    city                                    national character varying(100),
    state                                   national character varying(100),
    country                                 national character varying(100),
    po_box                                  national character varying(100),
    zipcode                                 national character varying(100),
    phone_numbers                           national character varying(100),
    fax                                     national character varying(100),    
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)    
);

CREATE UNIQUE INDEX gift_cards_gift_card_number_uix
ON sales.gift_cards(gift_card_number)
WHERE deleted = 0;

--TODO: Create a trigger to disable deleting a gift card if the balance is not zero.

CREATE TABLE sales.gift_card_transactions
(
    transaction_id                          bigint IDENTITY PRIMARY KEY,
    gift_card_id                            integer NOT NULL REFERENCES sales.gift_cards,
    value_date                                date,
    book_date                                date,
    transaction_master_id                   bigint NOT NULL REFERENCES finance.transaction_master,
    transaction_type                        national character varying(2) NOT NULL
                                            CHECK(transaction_type IN('Dr', 'Cr')),
    amount                                  dbo.money_strict
);

CREATE TABLE sales.late_fee
(
    late_fee_id                             integer IDENTITY PRIMARY KEY,
    late_fee_code                           national character varying(24) NOT NULL,
    late_fee_name                           national character varying(500) NOT NULL,
    is_flat_amount                          bit NOT NULL DEFAULT(0),
    rate                                    numeric(24, 23) NOT NULL,
    account_id                                 integer NOT NULL REFERENCES finance.accounts,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE sales.late_fee_postings
(
    transaction_master_id                   bigint PRIMARY KEY REFERENCES finance.transaction_master,
    customer_id                             integer NOT NULL REFERENCES inventory.customers,
    value_date                              date NOT NULL,
    late_fee_tran_id                        bigint NOT NULL REFERENCES finance.transaction_master,
    amount                                  dbo.money_strict
);

CREATE TABLE sales.price_types
(
    price_type_id                           integer IDENTITY PRIMARY KEY,
    price_type_code                         national character varying(24) NOT NULL,
    price_type_name                         national character varying(500) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE sales.item_selling_prices
(
    item_selling_price_id                   bigint IDENTITY PRIMARY KEY,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    customer_type_id                        integer REFERENCES inventory.customer_types,
    price_type_id                           integer REFERENCES sales.price_types,
    includes_tax                            bit NOT NULL DEFAULT(0),
    price                                   dbo.money_strict NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE sales.payment_terms
(
    payment_term_id                         integer IDENTITY PRIMARY KEY,
    payment_term_code                       national character varying(24) NOT NULL,
    payment_term_name                       national character varying(500) NOT NULL,
    due_on_date                             bit NOT NULL DEFAULT(0),
    due_days                                dbo.integer_strict2 NOT NULL DEFAULT(0),
    due_frequency_id                        integer REFERENCES finance.frequencies,
    grace_period                            integer NOT NULL DEFAULT(0),
    late_fee_id                             integer REFERENCES sales.late_fee,
    late_fee_posting_frequency_id           integer REFERENCES finance.frequencies,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)    
);


CREATE TABLE sales.cashiers
(
    cashier_id                              integer IDENTITY PRIMARY KEY,
    cashier_code                            national character varying(12) NOT NULL,
    pin_code                                national character varying(8) NOT NULL,
    associated_user_id                      integer NOT NULL REFERENCES account.users,
    counter_id                              integer NOT NULL REFERENCES inventory.counters,
    valid_from                              date NOT NULL,
    valid_till                              date NOT NULL,
                                            CHECK(valid_till >= valid_from),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE sales.cashier_login_info
(
    cashier_login_info_id                   uniqueidentifier PRIMARY KEY DEFAULT(NEWID()),
    counter_id                              integer REFERENCES inventory.counters,
    cashier_id                              integer REFERENCES sales.cashiers,
    login_date                              DATETIMEOFFSET NOT NULL,
    success                                 bit NOT NULL,
    attempted_by                            integer NOT NULL REFERENCES account.users,
    browser                                 national character varying(1000),
    ip_address                              national character varying(1000),
    user_agent                              national character varying(1000),    
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);



CREATE TABLE sales.quotations
(
    quotation_id                            bigint IDENTITY PRIMARY KEY,
    value_date                              date NOT NULL,
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETDATE()),
    customer_id                             integer NOT NULL REFERENCES inventory.customers,
    price_type_id                           integer NOT NULL REFERENCES sales.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                    national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE sales.quotation_details
(
    quotation_detail_id                     bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint NOT NULL REFERENCES sales.quotations,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   dbo.money_strict NOT NULL,
    discount_rate                           dbo.decimal_strict2 NOT NULL DEFAULT(0),    
    tax                                     dbo.money_strict2 NOT NULL DEFAULT(0),    
    shipping_charge                         dbo.money_strict2 NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                dbo.decimal_strict2 NOT NULL
);


CREATE TABLE sales.orders
(
    order_id                                bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint REFERENCES sales.quotations,
    value_date                              date NOT NULL,
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETDATE()),
    customer_id                             integer NOT NULL REFERENCES inventory.customers,
    price_type_id                           integer NOT NULL REFERENCES sales.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                   national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE sales.order_details
(
    order_detail_id                         bigint IDENTITY PRIMARY KEY,
    order_id                                bigint NOT NULL REFERENCES sales.orders,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   dbo.money_strict NOT NULL,
    discount_rate                           dbo.decimal_strict2 NOT NULL DEFAULT(0),    
    tax                                     dbo.money_strict2 NOT NULL DEFAULT(0),    
    shipping_charge                         dbo.money_strict2 NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                dbo.decimal_strict2 NOT NULL
);


CREATE TABLE sales.coupons
(
    coupon_id                                   integer IDENTITY PRIMARY KEY,
    coupon_name                                 national character varying(100) NOT NULL,
    coupon_code                                 national character varying(100) NOT NULL,
    discount_rate                               dbo.decimal_strict NOT NULL,
    is_percentage                               bit NOT NULL DEFAULT(0),
    maximum_discount_amount                     dbo.decimal_strict,
    associated_price_type_id                    integer REFERENCES sales.price_types,
    minimum_purchase_amount                     dbo.decimal_strict2,
    maximum_purchase_amount                     dbo.decimal_strict2,
    begins_from                                 date,
    expires_on                                  date,
    maximum_usage                               dbo.integer_strict,
    enable_ticket_printing                      bit,
    for_ticket_of_price_type_id                 integer REFERENCES sales.price_types,
    for_ticket_having_minimum_amount            dbo.decimal_strict2,
    for_ticket_having_maximum_amount            dbo.decimal_strict2,
    for_ticket_of_unknown_customers_only        bit,
    audit_user_id                               integer REFERENCES account.users,
    audit_ts                                    DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                        bit DEFAULT(0)    
);

CREATE UNIQUE INDEX coupons_coupon_code_uix
ON sales.coupons(coupon_code);



CREATE TABLE sales.sales
(
    sales_id                                bigint IDENTITY PRIMARY KEY,
    invoice_number                            bigint NOT NULL,
    fiscal_year_code                        national character varying(12) NOT NULL REFERENCES finance.fiscal_year,
    cash_repository_id                        integer REFERENCES finance.cash_repositories,
    price_type_id                            integer NOT NULL REFERENCES sales.price_types,
    sales_order_id                            bigint REFERENCES sales.orders,
    sales_quotation_id                        bigint REFERENCES sales.quotations,
    transaction_master_id                    bigint NOT NULL REFERENCES finance.transaction_master,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    counter_id                              integer NOT NULL REFERENCES inventory.counters,
    customer_id                             integer REFERENCES inventory.customers,
    salesperson_id                            integer REFERENCES account.users,
    total_amount                            dbo.money_strict NOT NULL,
    coupon_id                                integer REFERENCES sales.coupons,
    is_flat_discount                        bit,
    discount                                dbo.decimal_strict2,
    total_discount_amount                    dbo.decimal_strict2,    
    is_credit                               bit NOT NULL DEFAULT(0),
    credit_settled                            bit,
    payment_term_id                         integer REFERENCES sales.payment_terms,
    tender                                  decimal(24, 4) NOT NULL,
    change                                  decimal(24, 4) NOT NULL,
    gift_card_id                            integer REFERENCES sales.gift_cards,
    check_number                            national character varying(100),
    check_date                              date,
    check_bank_name                         national character varying(1000),
    check_amount                            dbo.money_strict2,
    check_cleared                           bit,    
    check_clear_date                        date,   
    check_clearing_memo                     national character varying(1000),
    check_clearing_transaction_master_id    bigint REFERENCES finance.transaction_master,
    reward_points                            numeric(24, 4) NOT NULL DEFAULT(0)
);

CREATE UNIQUE INDEX sales_invoice_number_fiscal_year_uix
ON sales.sales(fiscal_year_code, invoice_number);


CREATE TABLE sales.customer_receipts
(
    receipt_id                              bigint IDENTITY PRIMARY KEY,
    transaction_master_id                   bigint NOT NULL REFERENCES finance.transaction_master,
    customer_id                             integer NOT NULL REFERENCES inventory.customers,
    currency_code                           national character varying(12) NOT NULL REFERENCES core.currencies,
    er_debit                                dbo.decimal_strict NOT NULL,
    er_credit                               dbo.decimal_strict NOT NULL,
    cash_repository_id                      integer NULL REFERENCES finance.cash_repositories,
    posted_date                             date NULL,
    tender                                  dbo.money_strict2,
    change                                  dbo.money_strict2,
    check_amount                            dbo.money_strict2,
    bank_name                               national character varying(1000),
    check_number                            national character varying(100),
    check_date                              date,
    gift_card_number                        national character varying(100)
);

CREATE INDEX customer_receipts_transaction_master_id_inx
ON sales.customer_receipts(transaction_master_id);

CREATE INDEX customer_receipts_customer_id_inx
ON sales.customer_receipts(customer_id);

CREATE INDEX customer_receipts_currency_code_inx
ON sales.customer_receipts(currency_code);

CREATE INDEX customer_receipts_cash_repository_id_inx
ON sales.customer_receipts(cash_repository_id);

CREATE INDEX customer_receipts_posted_date_inx
ON sales.customer_receipts(posted_date);



CREATE TABLE sales.returns
(
    return_id                               bigint IDENTITY PRIMARY KEY,
    sales_id                                bigint NOT NULL REFERENCES sales.sales,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    transaction_master_id                    bigint NOT NULL REFERENCES finance.transaction_master,
    return_transaction_master_id            bigint NOT NULL REFERENCES finance.transaction_master,
    counter_id                              integer NOT NULL REFERENCES inventory.counters,
    customer_id                             integer REFERENCES inventory.customers,
    price_type_id                            integer NOT NULL REFERENCES sales.price_types,
    is_credit                                bit
);


CREATE TABLE sales.opening_cash
(
    opening_cash_id                            bigint IDENTITY PRIMARY KEY,
    user_id                                    integer NOT NULL REFERENCES account.users,
    transaction_date                        date NOT NULL,
    amount                                    decimal(24, 4) NOT NULL,
    provided_by                                national character varying(1000) NOT NULL DEFAULT(''),
    memo                                    national character varying(4000) DEFAULT(''),
    closed                                    bit NOT NULL DEFAULT(0),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET NULL DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE UNIQUE INDEX opening_cash_transaction_date_user_id_uix
ON sales.opening_cash(user_id, transaction_date);

CREATE TABLE sales.closing_cash
(
    closing_cash_id                            bigint IDENTITY PRIMARY KEY,
    user_id                                    integer NOT NULL REFERENCES account.users,
    transaction_date                        date NOT NULL,
    opening_cash                            decimal(24, 4) NOT NULL,
    total_cash_sales                        decimal(24, 4) NOT NULL,
    submitted_to                            national character varying(1000) NOT NULL DEFAULT(''),
    memo                                    national character varying(4000) NOT NULL DEFAULT(''),
    deno1000                                integer DEFAULT(0),
    deno500                                    integer DEFAULT(0),
    deno250                                    integer DEFAULT(0),
    deno200                                    integer DEFAULT(0),
    deno100                                    integer DEFAULT(0),
    deno50                                    integer DEFAULT(0),
    deno25                                    integer DEFAULT(0),
    deno20                                    integer DEFAULT(0),
    deno10                                    integer DEFAULT(0),
    deno5                                    integer DEFAULT(0),
    deno2                                    integer DEFAULT(0),
    deno1                                    integer DEFAULT(0),
    coins                                    decimal(24, 4) DEFAULT(0),
    submitted_cash                            decimal(24, 4) NOT NULL,
    approved_by                                integer REFERENCES account.users,
    approval_memo                            national character varying(4000),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET NULL DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE UNIQUE INDEX closing_cash_transaction_date_user_id_uix
ON sales.closing_cash(user_id, transaction_date);


CREATE TYPE sales.sales_detail_type
AS TABLE
(
    store_id            integer,
    transaction_type    national character varying(2),
    item_id               integer,
    quantity            dbo.decimal_strict,
    unit_id               integer,
    price               dbo.money_strict,
    discount_rate       dbo.money_strict2,
    tax                 dbo.money_strict2,
    shipping_charge     dbo.money_strict2
);




GO