-- banking_analysis_phase 2

use banking_analytics;

select * from customers limit 5;

-- 1.1  Standardize text columns (trim spaces, fix casing)
update customers set 
first_name = CONCAT(UPPER(LEFT(TRIM(first_name),1)), LOWER(SUBSTRING(TRIM(first_name),2))),
last_name  = CONCAT(UPPER(LEFT(TRIM(last_name),1)), LOWER(SUBSTRING(TRIM(last_name),2))),
city       = CONCAT(UPPER(LEFT(TRIM(city),1)), LOWER(SUBSTRING(TRIM(city),2))),
occupation = TRIM(occupation);

select * from branches limit 5;

UPDATE branches SET
branch_name  = TRIM(branch_name),
city         = CONCAT(UPPER(LEFT(TRIM(city),1)), LOWER(SUBSTRING(TRIM(city),2)));

 
-- -------------------------------------------------------------
-- 1.2  Fix NULL emails — replace with a placeholder
-- -------------------------------------------------------------

-- check if there is null values or not in email
select * from customers 
where email is null or email = '';

UPDATE customers
set email = concat('first_name','customer_id','@gmail.com')
where email is NULL or email = '';


-- -------------------------------------------------------------
-- 1.3  Fix invalid credit scores (must be 300–900)
-- -------------------------------------------------------------
UPDATE customers
SET credit_score = 300
WHERE credit_score < 300;

UPDATE customers
SET credit_score = 900
WHERE credit_score > 900;


-- -------------------------------------------------------------
-- 1.4  Fix negative balances in accounts
-- -------------------------------------------------------------
UPDATE accounts
SET balance = 0.00
WHERE balance < 0;   

-- -------------------------------------------------------------
-- 1.5  Fix negative amounts in transactions
-- -------------------------------------------------------------
UPDATE transactions
SET amount = ABS(amount)
WHERE amount < 0;   


-- -------------------------------------------------------------
-- 1.6  Set fraud_category = 'None' where is_fraud = 0
-- -------------------------------------------------------------
UPDATE transactions
SET fraud_category = 'None'
WHERE is_fraud = 0 AND (fraud_category IS NULL OR fraud_category = '');


-- -------------------------------------------------------------
-- 1.7  Remove duplicate transactions (same ref, keep lowest id)
-- -------------------------------------------------------------
DELETE t1 FROM transactions t1
INNER JOIN transactions t2
    ON t1.transaction_ref = t2.transaction_ref
    AND t1.transaction_id > t2.transaction_id;
    
    
-- -------------------------------------------------------------
-- 1.8  Flag dormant accounts (no transaction in last 365 days)
-- -------------------------------------------------------------
UPDATE accounts a
SET a.status = 'Dormant'
WHERE a.status = 'Active'
  AND a.account_id NOT IN (
      SELECT DISTINCT account_id
      FROM transactions
      WHERE transaction_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
  );
      

-- -------------------------------------------------------------
-- 1.9  Verify cleaning results
-- -------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM customers WHERE email LIKE 'unknown_%') AS missing_emails_fixed,
    (SELECT COUNT(*) FROM accounts  WHERE balance = 0)            AS zero_balance_accounts,
    (SELECT COUNT(*) FROM transactions WHERE amount <= 0)         AS invalid_amount_txns,
    (SELECT COUNT(*) FROM transactions WHERE is_fraud = 1)        AS fraud_transactions,
    (SELECT COUNT(*) FROM loans WHERE loan_status = 'NPA')        AS npa_loans;  