CREATE DATABASE IF NOT EXISTS retail_banking;
USE retail_banking; 


CREATE TABLE branches (
    branch_id       VARCHAR(10) PRIMARY KEY,
    branch_name     VARCHAR(100) NOT NULL,
    city            VARCHAR(50),
    state           VARCHAR(30),
    region          VARCHAR(30),
    opening_date    DATE,
    employee_count  INT
);

CREATE TABLE customers (
    customer_id     VARCHAR(20) PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50),
    date_of_birth   DATE,
    gender          VARCHAR(20),
    city            VARCHAR(50),
    state           VARCHAR(30),
    customer_since  DATE,
    kyc_status      VARCHAR(20),
    segment         VARCHAR(30),
    annual_income   DECIMAL(12,2),
    credit_score    INT,
    is_active       VARCHAR(3) DEFAULT 'Yes'
);

CREATE TABLE accounts (
    account_id       VARCHAR(20) PRIMARY KEY,
    customer_id      VARCHAR(20) NOT NULL,
    branch_id        VARCHAR(10) NOT NULL,
    account_type     VARCHAR(30) NOT NULL,
    open_date        DATE,
    close_date       DATE,
    current_balance  DECIMAL(15,2) DEFAULT 0,
    interest_rate    DECIMAL(5,2),
    overdraft_limit  DECIMAL(12,2),
    status           VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)   REFERENCES branches(branch_id)
);

CREATE TABLE cards (
    card_id              VARCHAR(20) PRIMARY KEY,
    account_id           VARCHAR(20) NOT NULL,
    card_type            VARCHAR(30),
    issue_date           DATE,
    expiry_date          DATE,
    credit_limit         DECIMAL(12,2),
    outstanding_balance  DECIMAL(12,2),
    reward_points        INT DEFAULT 0,
    is_active            VARCHAR(3),
    network              VARCHAR(20),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE transactions (
    transaction_id    VARCHAR(20) PRIMARY KEY,
    account_id        VARCHAR(20) NOT NULL,
    transaction_date  DATE,
    transaction_time  TIME,
    transaction_type  VARCHAR(30),
    amount            DECIMAL(15,2),
    channel           VARCHAR(30),
    description       VARCHAR(50),
    balance_after     DECIMAL(15,2),
    status            VARCHAR(20),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE loans (
    loan_id              VARCHAR(20) PRIMARY KEY,
    customer_id          VARCHAR(20) NOT NULL,
    branch_id            VARCHAR(10) NOT NULL,
    loan_type            VARCHAR(30),
    principal_amount     DECIMAL(15,2),
    interest_rate        DECIMAL(5,2),
    tenure_months        INT,
    disbursement_date    DATE,
    maturity_date        DATE,
    emi_amount           DECIMAL(12,2),
    outstanding_balance  DECIMAL(15,2),
    loan_status          VARCHAR(30),
    purpose              VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)   REFERENCES branches(branch_id)
);

CREATE TABLE loan_payments (
    payment_id        VARCHAR(20) PRIMARY KEY,
    loan_id           VARCHAR(20) NOT NULL,
    payment_date      DATE,
    scheduled_amount  DECIMAL(12,2),
    paid_amount       DECIMAL(12,2),
    principal_paid    DECIMAL(12,2),
    interest_paid     DECIMAL(12,2),
    penalty           DECIMAL(12,2) DEFAULT 0,
    days_late         INT DEFAULT 0,
    payment_method    VARCHAR(30),
    status            VARCHAR(20),
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);

SHOW TABLES;
-- =====================================================
-- FIX: Importing accounts.csv when close_date is blank
-- =====================================================
-- PROBLEM: Active accounts have an empty close_date in the CSV.
-- The Import Wizard cannot put an empty value into a DATE column,
-- so it skipped those rows (only 203 of 700 loaded).
-- SOLUTION: Load everything as plain text into a temporary
-- "staging" table first, then convert blanks to NULL while
-- copying into the real table.

-- STEP 1: Remove the 203 partially loaded rows from accounts.
-- DELETE FROM accounts; 

-- STEP 2: Check that the table is now empty.
-- Expected result: 0
SELECT COUNT(*) FROM accounts;

-- STEP 2: Create a temporary staging table.
-- Every column is VARCHAR (text), so blank values are accepted
-- and no row gets rejected. There are no keys or constraints here.
CREATE TABLE accounts_stg (
    account_id      VARCHAR(20),
    customer_id     VARCHAR(20),
    branch_id       VARCHAR(10),
    account_type    VARCHAR(30),
    open_date       VARCHAR(20),
    close_date      VARCHAR(20),
    current_balance VARCHAR(30),
    interest_rate   VARCHAR(20),
    overdraft_limit VARCHAR(30),
    status          VARCHAR(20)
);

-- STEP 3 (done in the wizard, not SQL):
-- Right-click accounts_stg -> Table Data Import Wizard
-- -> choose accounts.csv. Expected result: 700 records imported.

-- STEP 4: Copy the data from the staging table into the real
-- accounts table.
-- NULLIF(column, '') returns NULL when the column is an empty
-- string, otherwise it returns the original value. This turns
-- blank dates and numbers into proper NULLs.
-- The text values are converted automatically to DATE and
-- DECIMAL types during the insert.
INSERT INTO accounts
SELECT account_id,
       customer_id,
       branch_id,
       account_type,
       NULLIF(open_date, ''),
       NULLIF(close_date, ''),
       NULLIF(current_balance, ''),
       NULLIF(interest_rate, ''),
       NULLIF(overdraft_limit, ''),
       status
FROM accounts_stg;

select * from accounts_stg ;

-- STEP 5: Verify that all rows loaded.
-- Expected result: 700
SELECT COUNT(*) FROM accounts;

-- STEP 6: Delete the staging table, because it is no longer needed.
-- DROP TABLE accounts_stg;


-- Count the rows in every table and compare with the project document.
-- Expected: branches 40, customers 500, accounts 700, cards 600,
-- transactions 5000, loans 300, loan_payments 2000.
SELECT 'branches' AS table_name, COUNT(*) AS row_count FROM branches
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'cards', COUNT(*) FROM cards
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'loan_payments', COUNT(*) FROM loan_payments;


-- ---------------------------------------------------------------------
-- SPRINT 4.1: CUSTOMER PROFILE AND SEGMENTATION
-- ---------------------------------------------------------------------

-- Check how active flags and transaction statuses are stored.
-- If the values differ from 'Yes' or 'Completed', change them
-- in the queries below.
SELECT DISTINCT is_active FROM customers;
SELECT DISTINCT status FROM transactions;


-- Q1. Total number of customers.
-- COUNT(*) counts every row in the customers table.
SELECT COUNT(*) AS total_customers FROM customers;



-- Q2. Total number of accounts.
SELECT COUNT(*) AS total_accounts FROM accounts;

-- Q3. Different account types available.
-- DISTINCT removes duplicates so each type appears once.
SELECT DISTINCT account_type FROM accounts;

-- Q4. Number of currently active customers.
-- WHERE filters to only the customers flagged as active.
SELECT COUNT(*) AS active_customers
FROM customers
WHERE is_active = 'Yes';

-- Q5. Different transaction types available.
SELECT DISTINCT transaction_type FROM transactions;

-- Q6. Total amount of completed transactions.
-- SUM adds up the amount column, only for completed transactions.
SELECT SUM(amount) AS total_completed_amount
FROM transactions
WHERE status = 'Completed';

-- Q7. Different loan types available.
SELECT DISTINCT loan_type FROM loans;

-- Q8. Total number of loans.
SELECT COUNT(*) AS total_loans FROM loans;

-- Q9. Different card types available.
SELECT DISTINCT card_type FROM cards;

-- Q10. Total outstanding loan balance (money still owed on loans).
SELECT SUM(outstanding_balance) AS total_outstanding_balance
FROM loans;

-- sprint 4 

-- Check the exact spelling of the values used in filters below.
SELECT DISTINCT segment FROM customers;
SELECT DISTINCT kyc_status FROM customers;
SELECT DISTINCT is_active FROM customers;

-- "TODAY" RULE FROM THE PROJECT DOC:
-- Use the latest transaction_date as today's date, not the real date.
SELECT MAX(transaction_date) AS today_for_analysis FROM transactions;

-- Q1. How many customers are in each segment, and what share
-- of the total does each segment make up?
-- GROUP BY splits customers by segment. The subquery gives the
-- grand total so we can calculate the percentage.
SELECT segment,
       COUNT(*) AS customers,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 1) AS pct_of_total
FROM customers
GROUP BY segment
ORDER BY customers DESC;

-- Q2. How do income and credit score differ by segment?
-- AVG gives the average value per segment, so we can see
-- whether higher segments really earn more and score higher.
SELECT segment,
       ROUND(AVG(annual_income), 0) AS avg_income,
       ROUND(AVG(credit_score), 0)  AS avg_credit_score
FROM customers
GROUP BY segment
ORDER BY avg_income DESC;

-- Q3. Which cities and states have the most customers?
-- Shows where the bank's customer base is concentrated.
SELECT state, city, COUNT(*) AS customers
FROM customers
GROUP BY state, city
ORDER BY customers DESC
LIMIT 10;

-- Q4. What is the gender split, and does it differ by segment?
SELECT segment, gender, COUNT(*) AS customers
FROM customers
GROUP BY segment, gender
ORDER BY segment, customers DESC;

-- Q5. What is the age profile of customers?
-- TIMESTAMPDIFF calculates age in years from date_of_birth up to
-- the analysis "today". CASE groups ages into bands.
SELECT CASE
         WHEN TIMESTAMPDIFF(YEAR, date_of_birth, (SELECT MAX(transaction_date) FROM transactions)) < 30 THEN 'Under 30'
         WHEN TIMESTAMPDIFF(YEAR, date_of_birth, (SELECT MAX(transaction_date) FROM transactions)) < 45 THEN '30-44'
         WHEN TIMESTAMPDIFF(YEAR, date_of_birth, (SELECT MAX(transaction_date) FROM transactions)) < 60 THEN '45-59'
         ELSE '60+'
       END AS age_band,
       COUNT(*) AS customers
FROM customers
GROUP BY age_band
ORDER BY age_band;

-- Q6. What is the KYC status mix, and how many customers are active?
-- KYC (Know Your Customer) incomplete customers may be a compliance risk.
SELECT kyc_status, is_active, COUNT(*) AS customers
FROM customers
GROUP BY kyc_status, is_active
ORDER BY kyc_status, is_active;

-- Q7. How long have customers been with the bank (tenure)?
-- Tenure = years between customer_since and analysis "today".
SELECT segment,
       ROUND(AVG(TIMESTAMPDIFF(YEAR, customer_since,
             (SELECT MAX(transaction_date) FROM transactions))), 1) AS avg_tenure_years
FROM customers
GROUP BY segment;

-- Q8. Do customers with a higher credit score earn more?
-- Groups credit scores into bands and compares average income.
SELECT CASE
         WHEN credit_score < 580 THEN 'Poor (<580)'
         WHEN credit_score < 670 THEN 'Fair (580-669)'
         WHEN credit_score < 740 THEN 'Good (670-739)'
         ELSE 'Excellent (740+)'
       END AS credit_band,
       COUNT(*) AS customers,
       ROUND(AVG(annual_income), 0) AS avg_income
FROM customers
GROUP BY credit_band
ORDER BY MIN(credit_score);

-- ---------------------------------------------------------------------
-- SPRINT 4.2: ACCOUNT USAGE AND BRANCH ACTIVITY
-- ---------------------------------------------------------------------
-- Check the exact spelling of values used in the filters below.
SELECT DISTINCT status FROM accounts;
SELECT DISTINCT account_type FROM accounts;
SELECT DISTINCT region FROM branches;


-- Q1. How many accounts are there of each type, and what is the
-- average balance and interest rate for each?
-- Shows which products are most popular and how they are priced.
SELECT account_type,
       COUNT(*) AS accounts,
       ROUND(AVG(current_balance), 2) AS avg_balance,
       ROUND(AVG(interest_rate), 2)   AS avg_interest_rate
FROM accounts
GROUP BY account_type
ORDER BY accounts DESC;

-- Q2. How many accounts are active vs closed, and how do their
-- balances differ?
-- Closed accounts holding a balance may need follow-up.
SELECT status,
       COUNT(*) AS accounts,
       ROUND(SUM(current_balance), 2) AS total_balance,
       ROUND(AVG(current_balance), 2) AS avg_balance
FROM accounts
GROUP BY status;

-- Q3. Which branches hold the most accounts and the most money?
-- JOIN links each account to its branch through branch_id.
SELECT b.branch_id, b.branch_name, b.city,
       COUNT(a.account_id) AS accounts,
       ROUND(SUM(a.current_balance), 2) AS total_balance
FROM branches b
JOIN accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY total_balance DESC
LIMIT 10;

-- Q4. How do regions compare in accounts and balances?
SELECT b.region,
       COUNT(a.account_id) AS accounts,
       ROUND(SUM(a.current_balance), 2) AS total_balance,
       ROUND(AVG(a.current_balance), 2) AS avg_balance
FROM branches b
JOIN accounts a ON b.branch_id = a.branch_id
GROUP BY b.region
ORDER BY total_balance DESC;

-- Q5. Which customers hold more than one account?
-- HAVING filters AFTER grouping (WHERE cannot be used on COUNT).
SELECT customer_id,
       COUNT(*) AS num_accounts,
       ROUND(SUM(current_balance), 2) AS combined_balance
FROM accounts
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY num_accounts DESC, combined_balance DESC;

-- Q6. How many customers hold 1, 2, 3+ accounts?
-- The inner query counts accounts per customer, the outer
-- query counts how many customers fall in each group.
SELECT num_accounts, COUNT(*) AS customers
FROM (SELECT customer_id, COUNT(*) AS num_accounts
      FROM accounts
      GROUP BY customer_id) t
GROUP BY num_accounts
ORDER BY num_accounts;

-- Q7. Which accounts use their overdraft facility, and how much
-- overdraft limit is offered by account type?
SELECT account_type,
       COUNT(*) AS accounts_with_overdraft,
       ROUND(AVG(overdraft_limit), 2) AS avg_overdraft_limit
FROM accounts
WHERE overdraft_limit > 0
GROUP BY account_type;

-- Q8. Which branches have the most transaction activity?
-- Joins three tables: branches -> accounts -> transactions.
SELECT b.branch_name, b.city,
       COUNT(t.transaction_id) AS transactions,
       ROUND(SUM(t.amount), 2) AS total_amount
FROM branches b
JOIN accounts a     ON b.branch_id = a.branch_id
JOIN transactions t ON a.account_id = t.account_id
GROUP BY b.branch_name, b.city
ORDER BY transactions DESC
LIMIT 10;

-- Q9. Which accounts are dormant (no transactions at all)?
-- LEFT JOIN keeps all accounts; those with no matching
-- transaction show NULL, which we filter for.
SELECT a.account_id, a.account_type, a.status, a.current_balance
FROM accounts a
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE t.transaction_id IS NULL;

-- Q10. Which customer segment holds the most balance?
-- Links accounts back to customers to bring in the segment.
SELECT c.segment,
       COUNT(a.account_id) AS accounts,
       ROUND(SUM(a.current_balance), 2) AS total_balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.segment
ORDER BY total_balance DESC;


-- Check the exact spelling of values used in the filters below.
SELECT DISTINCT transaction_type FROM transactions;
SELECT DISTINCT channel FROM transactions;
SELECT DISTINCT status FROM transactions;
SELECT DISTINCT description FROM transactions;

-- =====================================================
-- SPRINT 4.3: TRANSACTION PATTERNS
-- =====================================================

-- Q1. Which transaction types are most common, and how much money
-- moves through each?
-- COUNT shows popularity; SUM and AVG show the money involved.
SELECT transaction_type,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_amount
FROM transactions
GROUP BY transaction_type
ORDER BY transactions DESC;

-- Q2. Which channels (ATM, online, branch, etc.) are used most?
-- Shows how customers prefer to bank.
SELECT channel,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_amount
FROM transactions
GROUP BY channel
ORDER BY transactions DESC;

-- Q3. Which transaction types are used in which channels?
-- Two columns in GROUP BY gives a type-by-channel breakdown.
SELECT transaction_type, channel, COUNT(*) AS transactions
FROM transactions
GROUP BY transaction_type, channel
ORDER BY transaction_type, transactions DESC;

-- Q4. What share of transactions are completed, failed or pending?
-- A high failure rate could point to service problems.
SELECT status,
       COUNT(*) AS transactions,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions), 1) AS pct_of_total
FROM transactions
GROUP BY status
ORDER BY transactions DESC;

-- Q5. What is the spread of transaction amounts?
-- MIN, MAX and AVG show the range; useful for spotting outliers.
SELECT MIN(amount) AS smallest,
       MAX(amount) AS largest,
       ROUND(AVG(amount), 2) AS average
FROM transactions;

-- Q6. How are transactions distributed across amount bands?
-- CASE groups each amount into a band so we can count per band.
SELECT CASE
         WHEN amount < 100   THEN 'Under 100'
         WHEN amount < 1000  THEN '100-999'
         WHEN amount < 5000  THEN '1,000-4,999'
         ELSE '5,000+'
       END AS amount_band,
       COUNT(*) AS transactions
FROM transactions
GROUP BY amount_band
ORDER BY MIN(amount);

-- Q7. What are the most common transaction descriptions?
-- Shows what customers spend and receive money on.
SELECT description,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM transactions
GROUP BY description
ORDER BY transactions DESC
LIMIT 10;

-- Q8. How does transaction activity change month by month?
-- DATE_FORMAT turns each date into 'YYYY-MM' to group by month.
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS month,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM transactions
GROUP BY month
ORDER BY month;

-- Q9. At what time of day are customers most active?
-- HOUR() pulls the hour (0-23) out of the time column.
SELECT HOUR(transaction_time) AS hour_of_day,
       COUNT(*) AS transactions
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Q10. Which day of the week is busiest?
-- DAYNAME gives the weekday name; DAYOFWEEK is used only to sort
-- the days in calendar order.
SELECT DAYNAME(transaction_date) AS weekday,
       COUNT(*) AS transactions
FROM transactions
GROUP BY weekday, DAYOFWEEK(transaction_date)
ORDER BY DAYOFWEEK(transaction_date);

-- Q11. Which account types have the most transaction activity?
-- Joins transactions to accounts to bring in the account type.
SELECT a.account_type,
       COUNT(t.transaction_id) AS transactions,
       ROUND(SUM(t.amount), 2) AS total_amount
FROM accounts a
JOIN transactions t ON a.account_id = t.account_id
GROUP BY a.account_type
ORDER BY transactions DESC;

-- Q12. Which customer segments transact the most?
-- Joins three tables: customers -> accounts -> transactions.
SELECT c.segment,
       COUNT(t.transaction_id) AS transactions,
       ROUND(AVG(t.amount), 2) AS avg_amount
FROM customers c
JOIN accounts a     ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.segment
ORDER BY transactions DESC;

-- Q13. Which 10 accounts are the most active?
SELECT account_id,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM transactions
GROUP BY account_id
ORDER BY transactions DESC
LIMIT 10;

-- Q14. How do transactions affect balances?
-- Compares the average balance left after each transaction type.
-- Low balance_after values after withdrawals may signal accounts
-- running close to zero or into overdraft.
SELECT transaction_type,
       ROUND(AVG(balance_after), 2) AS avg_balance_after,
       MIN(balance_after) AS lowest_balance_after
FROM transactions
GROUP BY transaction_type;

-- Q15. Are there transactions that left an account with a
-- negative balance?
SELECT COUNT(*) AS negative_balance_transactions
FROM transactions
WHERE balance_after < 0;


-- Check the exact spelling of values used in the filters below.
SELECT DISTINCT loan_type FROM loans;
SELECT DISTINCT loan_status FROM loans;
SELECT DISTINCT purpose FROM loans;
SELECT DISTINCT status FROM loan_payments;
SELECT DISTINCT payment_method FROM loan_payments;

-- =====================================================
-- SPRINT 4.4: LOAN PERFORMANCE AND REPAYMENT BEHAVIOUR
-- =====================================================

-- Q1. How many loans are there of each type, and how much money
-- has been lent and is still owed?
-- Shows which loan products are biggest and how much is outstanding.
SELECT loan_type,
       COUNT(*) AS loans,
       ROUND(SUM(principal_amount), 2)    AS total_lent,
       ROUND(SUM(outstanding_balance), 2) AS total_outstanding,
       ROUND(AVG(interest_rate), 2)       AS avg_interest_rate
FROM loans
GROUP BY loan_type
ORDER BY total_lent DESC;

-- Q2. What share of each loan has been repaid so far?
-- (principal - outstanding) / principal gives the repaid percentage.
SELECT loan_type,
       ROUND((1 - SUM(outstanding_balance) / SUM(principal_amount)) * 100, 1) AS pct_repaid
FROM loans
GROUP BY loan_type
ORDER BY pct_repaid DESC;

-- Q3. What are the loans being used for (purpose)?
SELECT purpose,
       COUNT(*) AS loans,
       ROUND(AVG(principal_amount), 2) AS avg_loan_amount
FROM loans
GROUP BY purpose
ORDER BY loans DESC;

-- Q4. How are loans split by status (active, closed, defaulted etc.)?
SELECT loan_status,
       COUNT(*) AS loans,
       ROUND(SUM(outstanding_balance), 2) AS outstanding_balance,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM loans), 1) AS pct_of_loans
FROM loans
GROUP BY loan_status
ORDER BY loans DESC;

-- Q5. Which loan types have the most problem loans?
-- Cross-tab of loan type vs. loan status.
SELECT loan_type, loan_status, COUNT(*) AS loans
FROM loans
GROUP BY loan_type, loan_status
ORDER BY loan_type, loans DESC;

-- Q6. What share of payments were made on time vs. late?
-- days_late > 0 means the customer paid after the due date.
SELECT CASE WHEN days_late > 0 THEN 'Late' ELSE 'On time' END AS payment_timing,
       COUNT(*) AS payments,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM loan_payments), 1) AS pct_of_payments
FROM loan_payments
GROUP BY payment_timing;

-- Q7. How late are the late payments?
-- Groups delays into bands to see how serious they are.
SELECT CASE
         WHEN days_late = 0  THEN 'On time'
         WHEN days_late <= 7  THEN '1-7 days'
         WHEN days_late <= 30 THEN '8-30 days'
         ELSE '30+ days'
       END AS delay_band,
       COUNT(*) AS payments,
       ROUND(SUM(penalty), 2) AS total_penalty
FROM loan_payments
GROUP BY delay_band
ORDER BY MIN(days_late);

-- Q8. How much penalty has been charged in total?
SELECT COUNT(*) AS payments_with_penalty,
       ROUND(SUM(penalty), 2) AS total_penalty,
       ROUND(AVG(penalty), 2) AS avg_penalty
FROM loan_payments
WHERE penalty > 0;

-- Q9. Are customers paying the full scheduled amount?
-- Compares what was due with what was actually paid.
SELECT ROUND(SUM(scheduled_amount), 2) AS total_due,
       ROUND(SUM(paid_amount), 2)      AS total_paid,
       ROUND(SUM(paid_amount) * 100.0 / SUM(scheduled_amount), 1) AS pct_collected
FROM loan_payments;

-- Q10. Which payment status values occur and how common are they?
SELECT status,
       COUNT(*) AS payments,
       ROUND(AVG(days_late), 1) AS avg_days_late
FROM loan_payments
GROUP BY status
ORDER BY payments DESC;

-- Q11. Which payment methods are used the most, and which have
-- the most late payments?
-- SUM(days_late > 0) counts late payments (true = 1, false = 0).
SELECT payment_method,
       COUNT(*) AS payments,
       SUM(days_late > 0) AS late_payments,
       ROUND(SUM(days_late > 0) * 100.0 / COUNT(*), 1) AS pct_late
FROM loan_payments
GROUP BY payment_method
ORDER BY payments DESC;

-- Q12. Which loan types have the worst repayment behaviour?
-- Joins loan_payments to loans to bring in the loan type.
SELECT l.loan_type,
       COUNT(p.payment_id) AS payments,
       ROUND(AVG(p.days_late), 1) AS avg_days_late,
       ROUND(SUM(p.days_late > 0) * 100.0 / COUNT(*), 1) AS pct_late,
       ROUND(SUM(p.penalty), 2) AS total_penalty
FROM loans l
JOIN loan_payments p ON l.loan_id = p.loan_id
GROUP BY l.loan_type
ORDER BY pct_late DESC;

-- Q13. How do branches compare on loans and repayment?
-- Joins three tables: branches -> loans -> loan_payments.
SELECT b.branch_name, b.city,
       COUNT(DISTINCT l.loan_id) AS loans,
       ROUND(SUM(DISTINCT l.outstanding_balance), 2) AS outstanding,
       ROUND(AVG(p.days_late), 1) AS avg_days_late
FROM branches b
JOIN loans l          ON b.branch_id = l.branch_id
JOIN loan_payments p  ON l.loan_id = p.loan_id
GROUP BY b.branch_name, b.city
ORDER BY avg_days_late DESC
LIMIT 10;

-- Q14. Which customers have the most late payments?
-- Useful list for the collections team.
SELECT l.customer_id,
       COUNT(*) AS late_payments,
       ROUND(SUM(p.penalty), 2) AS total_penalty
FROM loans l
JOIN loan_payments p ON l.loan_id = p.loan_id
WHERE p.days_late > 0
GROUP BY l.customer_id
ORDER BY late_payments DESC
LIMIT 10;

-- Q15. Which loans are past maturity but still have a balance?
-- "Today" = the latest transaction_date, per the project rule.
SELECT loan_id, customer_id, loan_type, maturity_date, outstanding_balance
FROM loans
WHERE maturity_date < (SELECT MAX(transaction_date) FROM transactions)
  AND outstanding_balance > 0
ORDER BY outstanding_balance DESC;

-- Q16. Do customers with lower credit scores pay late more often?
-- Joins customers -> loans -> loan_payments.
SELECT CASE
         WHEN c.credit_score < 580 THEN 'Poor (<580)'
         WHEN c.credit_score < 670 THEN 'Fair (580-669)'
         WHEN c.credit_score < 740 THEN 'Good (670-739)'
         ELSE 'Excellent (740+)'
       END AS credit_band,
       COUNT(*) AS payments,
       ROUND(SUM(p.days_late > 0) * 100.0 / COUNT(*), 1) AS pct_late
FROM customers c
JOIN loans l          ON c.customer_id = l.customer_id
JOIN loan_payments p  ON l.loan_id = p.loan_id
GROUP BY credit_band
ORDER BY MIN(c.credit_score);

-- Check the exact spelling of values used in the filters below.
SELECT DISTINCT card_type FROM cards;
SELECT DISTINCT network FROM cards;
SELECT DISTINCT is_active FROM cards;

-- =====================================================
-- SPRINT 4.5: CARD USAGE AND PRODUCT ENGAGEMENT
-- =====================================================

-- Q1. How many cards are there of each type, and what are the
-- average credit limit and outstanding balance?
-- Shows which card products are most common and how much credit
-- the bank has extended through each.
SELECT card_type,
       COUNT(*) AS cards,
       ROUND(AVG(credit_limit), 2)         AS avg_credit_limit,
       ROUND(AVG(outstanding_balance), 2)  AS avg_outstanding
FROM cards
GROUP BY card_type
ORDER BY cards DESC;

-- Q2. How much of the credit limit is being used (utilization)?
-- outstanding / limit shows how heavily customers use their cards.
-- High utilization can signal risk; very low may mean idle cards.
-- NULLIF avoids division by zero for cards with a 0 limit.
SELECT card_type,
       ROUND(SUM(outstanding_balance) * 100.0 / NULLIF(SUM(credit_limit), 0), 1) AS utilization_pct
FROM cards
WHERE credit_limit > 0
GROUP BY card_type
ORDER BY utilization_pct DESC;

-- Q3. How many cards are active vs inactive?
SELECT is_active,
       COUNT(*) AS cards,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cards), 1) AS pct_of_cards,
       ROUND(AVG(outstanding_balance), 2) AS avg_outstanding
FROM cards
GROUP BY is_active;

-- Q4. Which card types have the most inactive cards?
-- Highlights products customers hold but do not use.
SELECT card_type, is_active, COUNT(*) AS cards
FROM cards
GROUP BY card_type, is_active
ORDER BY card_type, is_active;

-- Q5. How do reward points differ by card type?
SELECT card_type,
       ROUND(AVG(reward_points), 0) AS avg_points,
       MAX(reward_points)           AS max_points,
       SUM(reward_points)           AS total_points
FROM cards
GROUP BY card_type
ORDER BY avg_points DESC;

-- Q6. Do active cards earn more reward points than inactive ones?
SELECT is_active,
       ROUND(AVG(reward_points), 0) AS avg_points
FROM cards
GROUP BY is_active;

-- Q7. How are cards split across networks (Visa, Mastercard etc.)?
SELECT network,
       COUNT(*) AS cards,
       ROUND(AVG(credit_limit), 2) AS avg_credit_limit,
       ROUND(AVG(outstanding_balance), 2) AS avg_outstanding
FROM cards
GROUP BY network
ORDER BY cards DESC;

-- Q8. Which cards have expired or will expire soon?
-- "Today" = latest transaction_date, per the project rule.
-- Expired but still marked active is a data/risk issue.
SELECT card_id, account_id, card_type, expiry_date, is_active
FROM cards
WHERE expiry_date < (SELECT MAX(transaction_date) FROM transactions)
ORDER BY expiry_date;

-- Q9. How many cards expire in the next 90 days?
-- DATE_ADD adds 90 days to "today" to define the window.
SELECT COUNT(*) AS cards_expiring_soon
FROM cards
WHERE expiry_date BETWEEN (SELECT MAX(transaction_date) FROM transactions)
                      AND DATE_ADD((SELECT MAX(transaction_date) FROM transactions), INTERVAL 90 DAY);

-- Q10. Which account types have the most cards linked?
-- Joins cards to accounts to bring in the account type.
SELECT a.account_type,
       COUNT(c.card_id) AS cards
FROM accounts a
JOIN cards c ON a.account_id = c.account_id
GROUP BY a.account_type
ORDER BY cards DESC;

-- Q11. Which customers hold cards, and how many?
-- Joins customers -> accounts -> cards.
SELECT cu.customer_id, cu.first_name, cu.last_name, cu.segment,
       COUNT(c.card_id) AS cards
FROM customers cu
JOIN accounts a ON cu.customer_id = a.customer_id
JOIN cards c    ON a.account_id = c.account_id
GROUP BY cu.customer_id, cu.first_name, cu.last_name, cu.segment
ORDER BY cards DESC
LIMIT 10;

-- Q12. How many customers have a card, and how many do not?
-- EXISTS checks whether at least one matching card is found for
-- each customer, without multiplying rows.
SELECT SUM(has_card) AS customers_with_card,
       COUNT(*) - SUM(has_card) AS customers_without_card
FROM (SELECT cu.customer_id,
             EXISTS (SELECT 1 FROM accounts a
                     JOIN cards c ON a.account_id = c.account_id
                     WHERE a.customer_id = cu.customer_id) AS has_card
      FROM customers cu) t;

-- Q13. How many banking products does each customer use?
-- Counts account, card and loan as separate products (0 or 1 each).
-- Every customer with an account counts as having the account product.
SELECT products_used,
       COUNT(*) AS customers
FROM (SELECT cu.customer_id,
             EXISTS (SELECT 1 FROM accounts a WHERE a.customer_id = cu.customer_id)
           + EXISTS (SELECT 1 FROM accounts a JOIN cards c ON a.account_id = c.account_id
                     WHERE a.customer_id = cu.customer_id)
           + EXISTS (SELECT 1 FROM loans l WHERE l.customer_id = cu.customer_id)
             AS products_used
      FROM customers cu) t
GROUP BY products_used
ORDER BY products_used;

-- Q14. Which customers use all three products (account, card, loan)?
-- These are the most engaged customers and best cross-sell targets
-- to learn from.
SELECT cu.customer_id, cu.segment, cu.annual_income, cu.credit_score
FROM customers cu
WHERE EXISTS (SELECT 1 FROM accounts a WHERE a.customer_id = cu.customer_id)
  AND EXISTS (SELECT 1 FROM accounts a JOIN cards c ON a.account_id = c.account_id
              WHERE a.customer_id = cu.customer_id)
  AND EXISTS (SELECT 1 FROM loans l WHERE l.customer_id = cu.customer_id);

-- Q15. Which segment is the most engaged with multiple products?
-- Counts per segment how many customers hold a card and a loan.
SELECT cu.segment,
       COUNT(*) AS customers,
       SUM(EXISTS (SELECT 1 FROM accounts a JOIN cards c ON a.account_id = c.account_id
                   WHERE a.customer_id = cu.customer_id)) AS with_card,
       SUM(EXISTS (SELECT 1 FROM loans l WHERE l.customer_id = cu.customer_id)) AS with_loan
FROM customers cu
GROUP BY cu.segment;

-- Q16. Do customers with loans also hold cards with high balances?
-- Looks at the relationship between cards and loans: total card
-- debt and loan balance for customers holding both.
SELECT cu.customer_id,
       ROUND((SELECT SUM(c.outstanding_balance)
              FROM accounts a JOIN cards c ON a.account_id = c.account_id
              WHERE a.customer_id = cu.customer_id), 2) AS card_debt,
       ROUND((SELECT SUM(l.outstanding_balance)
              FROM loans l WHERE l.customer_id = cu.customer_id), 2) AS loan_balance
FROM customers cu
WHERE EXISTS (SELECT 1 FROM accounts a JOIN cards c ON a.account_id = c.account_id
              WHERE a.customer_id = cu.customer_id)
  AND EXISTS (SELECT 1 FROM loans l WHERE l.customer_id = cu.customer_id)
ORDER BY card_debt + loan_balance DESC
LIMIT 10;



-- =====================================================================
-- FINDINGS AND BUSINESS INSIGHTS
-- Paste this whole block at the very END of Retail_Banking.sql
-- (after the last query of Sprint 4.5). Comments only, nothing runs.
-- =====================================================================


-- =====================================================================
-- PART A: INSIGHTS BY SPRINT
-- =====================================================================

-- ---------------------------------------------------------------------
-- SPRINT 4.1: CUSTOMER PROFILE AND SEGMENTATION
-- ---------------------------------------------------------------------

-- INSIGHT 4.1 Q1: Customers are spread fairly evenly across 6 segments.
-- Student is the largest (100 customers, 20.0%) and Senior the smallest
-- (73 customers, 14.6%). No single segment dominates the customer base.

-- INSIGHT 4.1 Q2: Average income does not follow the segment names.
-- Student (158,117) earns about as much as Premium (158,668) and more than
-- Wealth (152,389). Credit scores are almost flat across all segments
-- (679 to 687). The current segments do not reflect customers' financial
-- strength, so the bank should consider re-segmenting by income and
-- credit score.

-- INSIGHT 4.1 Q6: Only about 29% of customers are fully KYC verified.
-- 105 customers (21%) have Failed KYC, and all of them are inactive, which
-- shows failed customers are being blocked correctly. However, 241 ACTIVE
-- customers (123 Partial and 118 Pending) have not completed KYC. That is
-- nearly half of all customers (48%) using the bank without full
-- verification, which is a clear compliance risk.


-- ---------------------------------------------------------------------
-- SPRINT 4.2: ACCOUNT USAGE AND BRANCH ACTIVITY
-- ---------------------------------------------------------------------

-- INSIGHT 4.2 Q1: IRA is the most common account type (136 accounts), but
-- Certificate of Deposit holds the highest average balance (22,057) and
-- pays the highest interest rate (4.62%). Checking (0.24%) and Business
-- Checking (0.51%) pay the least. Checking also has the lowest average
-- balance (3,964), so it is used for everyday spending rather than saving.

-- INSIGHT 4.2 Q2: 497 accounts are active and hold 10.2 million in total
-- (average 20,520 each). 203 accounts (29%) are closed, and all of them
-- have a zero balance. Accounts are being closed properly, with no money
-- left behind.

-- INSIGHT 4.2 Q3: Atlanta (BR025) holds the most money (501,926) even
-- though it has only 18 accounts, so it has the highest average balance
-- (about 27,885 per account). San Diego (BR004) has the most accounts (27)
-- but ranks second in balance (438,115). Two different branches are both
-- named "Washington Branch" (BR023 and BR040), so queries should group by
-- branch_id and not by branch_name.

-- INSIGHT 4.2 Q9: The result shows one dormant account, ACC0000161
-- (Business Checking). It is closed with a zero balance, so it is not a
-- retention risk. Every open account has made at least one transaction.


-- ---------------------------------------------------------------------
-- SPRINT 4.3: TRANSACTION PATTERNS
-- ---------------------------------------------------------------------

-- INSIGHT 4.3 Q1: The six transaction types are used almost equally
-- (784 to 858 each). Transfer (858) and ATM Withdrawal (857) are the most
-- common. Interest moves the most money (6.39 million) and Credit has the
-- highest average amount (7,759). DATA NOTE: Fee transactions average about
-- 6,997, which is unrealistically high for fees, so the dataset is
-- probably synthetic.

-- INSIGHT 4.3 Q2: Online (1,470) is the most used channel, followed by
-- Branch (1,144) and Mobile (1,024). Online and Mobile together make up
-- about half of all transactions (49.9%). POS (281) and Wire Transfer (224)
-- are small. Digital channels are now as important as branches and ATMs.

-- INSIGHT 4.3 Q4: Only 33.8% of transactions are completed. 33.7% are
-- pending and 32.6% have failed. A failure rate this high, together with
-- the same share still pending, points to a serious processing or service
-- problem.

-- INSIGHT 4.3 Q15: No transaction left an account with a negative balance
-- (0 found), so overdraft limits are not being breached.


-- ---------------------------------------------------------------------
-- SPRINT 4.4: LOAN PERFORMANCE AND REPAYMENT BEHAVIOUR
-- ---------------------------------------------------------------------

-- INSIGHT 4.4 Q3: Education is the most common loan purpose (64 loans,
-- 21% of the 300). Home Purchase is the least common (42 loans) but has the
-- largest average loan (259,769). Average loan sizes are close across all
-- purposes (228,424 to 259,769), so loan size does not depend much on
-- purpose.

-- INSIGHT 4.4 Q4: Loan quality is the biggest risk in the data. 86 loans
-- (28.7%) are Defaulted and 83 (27.7%) are In Arrears. Together that is 56%
-- of all loans. Only 65 loans (21.7%) are performing normally. Defaulted
-- and In Arrears loans hold 39.2 million of the 53.4 million outstanding
-- (about 73%).

-- INSIGHT 4.4 Q6: 75% of payments (1,500) are made on time and 25% (500)
-- are late. A quarter of all payments being late is a significant
-- collections issue.

-- INSIGHT 4.4 Q12: Home loans have the highest late-payment rate (28.2%),
-- followed by Business (26.9%) and Auto (26.1%). Credit Builder has the
-- lowest (21.7%). Education loans have the highest total penalty (20,818)
-- because they have the most payments (424), even though their late rate
-- (23.1%) is below average. The average delay is similar across types
-- (5.2 to 6.3 days). Total penalty across all loans is about 93,961.

-- INSIGHT 4.4 Q15: Several loans are well past their maturity date but
-- still owe large balances. The top six alone owe about 2.69 million
-- (428,121 to 478,873 each), with maturity dates between 2022 and 2024.
-- These loans are overdue beyond their full term and should go to the
-- recovery team first.


-- ---------------------------------------------------------------------
-- SPRINT 4.5: CARD USAGE AND PRODUCT ENGAGEMENT
-- ---------------------------------------------------------------------

-- INSIGHT 4.5 Q2: Utilization is reported only for Credit cards, at 41.8%.
-- That is a healthy level, with room to grow before it becomes a risk.

-- INSIGHT 4.5 Q3: Only 37 of the 600 cards (6.2%) are active. 563 cards
-- (93.8%) are inactive. Inactive cards still carry an average outstanding
-- balance of about 4,095, the same as active cards (4,095), so being
-- inactive does not mean the card has no debt. The bank has issued many
-- cards that customers are not using.

-- INSIGHT 4.5 Q5: Reward points are almost the same for both card types
-- (Credit averages 24,790 and Debit 24,490), with similar maximums (about
-- 49,800 and 49,984). Debit cards have the larger total (8.77 million vs
-- 6.00 million) only because there are more of them (about 358 Debit vs
-- 242 Credit cards). Reward earning does not depend on card type, so the
-- rewards scheme does not give Credit cards an advantage.

-- INSIGHT 4.5 Q8: All the expired cards visible in the result (expiry dates
-- from 2018 to 2019) are marked inactive, so no expired card appears to be
-- still active. This is expected, because 93.8% of all cards are inactive
-- (see Q3).

-- INSIGHT 4.5 Q13: 124 customers (24.8%) use all 3 products (account, card
-- and loan) and 192 (38.4%) use 2, so 63% hold two or more products. 110
-- customers hold only 1 product and 74 (14.8%) hold none, which makes them
-- the main cross-sell and onboarding targets.


-- =====================================================================
-- PART B: CONCLUSIONS
-- =====================================================================

-- 1. LOAN RISK IS THE BANK'S BIGGEST PROBLEM.
--    56% of loans are Defaulted or In Arrears, and these loans hold about
--    73% of the 53.4 million outstanding. A quarter of all loan payments
--    are late, and some loans are still unpaid years after their maturity
--    date.

-- 2. TRANSACTION PROCESSING NEEDS ATTENTION.
--    Only about one third of transactions are completed. The rest are
--    pending or failed, in almost equal shares.

-- 3. CUSTOMERS ARE MOVING TO DIGITAL CHANNELS.
--    Online and Mobile together handle about half of all transactions, as
--    much as Branch, ATM, POS and Wire combined.

-- 4. ACCOUNT MANAGEMENT IS HEALTHY.
--    Closed accounts have zero balances, no transaction leaves an account
--    negative, and open accounts are all in use.

-- 5. SEGMENTS DO NOT MATCH CUSTOMER VALUE.
--    Segments show almost the same income and credit score, so the
--    segment labels give little help in targeting customers.

-- 6. CROSS-SELLING HAS ROOM TO GROW.
--    Only a quarter of customers use all three products. 184 customers
--    use one product or none.

-- 7. KYC COMPLIANCE HAS GAPS.
--    241 active customers have only Partial or Pending KYC, which is
--    nearly half of all customers. Only about 29% are fully verified.

-- 8. MOST CARDS ARE NOT USED.
--    93.8% of cards are inactive, so most issued cards produce no
--    engagement.


-- =====================================================================
-- PART C: RECOMMENDATIONS
-- =====================================================================

-- 1. Set up a dedicated recovery team for Defaulted and In Arrears loans.
--    Start with loans past their maturity date that still carry the
--    largest balances.

-- 2. Send early payment reminders and offer restructuring for Home,
--    Business and Auto loans, which have the highest late-payment rates.

-- 3. Investigate the failed and pending transactions by channel and by
--    transaction type to find the root cause, and set a target for the
--    completed rate.

-- 4. Invest in the Online and Mobile channels, because they already carry
--    half of all transactions.

-- 5. Rebuild the customer segments using income and credit score so that
--    marketing and pricing can be targeted properly.

-- 6. Run cross-sell campaigns aimed at the 110 customers with one product
--    and onboarding offers for the 74 customers with none. Offer cards to
--    existing account holders, since credit card utilization (41.8%) shows
--    room to grow safely.

-- 7. Improve data quality. Fix the unrealistic Fee amounts, and make
--    branch names unique (two branches are both named Washington Branch).

-- 8. Start a KYC completion drive for the 241 active customers with Partial
--    or Pending status, and restrict services for those who do not complete
--    it by a deadline.

-- 9. Run a card activation campaign (offers, reward bonuses) for the 563
--    inactive cards, and review whether the cards that stay unused should
--    be closed.


-- =====================================================================
-- PART D: SPRINT 1.4 ANALYTICAL THINKING (NO SQL)
-- =====================================================================
-- Write each answer in your own words before submitting.

-- 1. Identify customers and their segment.
--    Table: customers. Columns: customer_id, first_name, last_name, segment.
--    Logic: read directly from the customers table.

-- 2. Find customers with more than one account.
--    Tables: customers, accounts. Columns: customer_id, account_id.
--    Logic: join on customer_id, count accounts per customer, keep those
--    with more than 1.

-- 3. Compare accounts across branches.
--    Tables: branches, accounts. Columns: branch_id, branch_name,
--    account_type, current_balance.
--    Logic: join on branch_id, group by branch, compare counts and balances.

-- 4. Understand how customers use accounts through transactions.
--    Tables: customers, accounts, transactions.
--    Logic: link customer_id to account_id to transactions, then look at
--    amount, type and date for each account.

-- 5. Find the most common transaction types and channels.
--    Table: transactions. Columns: transaction_type, channel.
--    Logic: no join needed. Count rows grouped by type and channel.

-- 6. See which customers have loans and what type.
--    Tables: customers, loans. Columns: customer_id, loan_type.
--    Logic: join on customer_id.

-- 7. Check whether loan customers pay on time.
--    Tables: customers, loans, loan_payments. Columns: days_late, penalty,
--    status, scheduled_amount, paid_amount.
--    Logic: join customer_id to loan_id to payments and check late days and
--    penalties.

-- 8. Compare loan performance across branches.
--    Tables: branches, loans, loan_payments.
--    Logic: join on branch_id, then loan_id. Compare loan_status,
--    outstanding_balance and days_late per branch.

-- 9. See which customers have cards.
--    Tables: customers, accounts, cards.
--    Logic: cards connect to customers only through accounts, so join
--    customer_id to account_id to cards.

-- 10. Understand how accounts, cards and loans are used together.
--     Tables: customers, accounts, cards, loans.
--     Logic: link everything by customer_id (cards through accounts) and
--     count how many products each customer holds.