# Retail Banking Transaction Analysis (MySQL)

A SQL analytics project on a retail bank's data. I act as a Data Analyst: I design the database, load the data, and answer business questions about customers, accounts, transactions, loans and cards.

## Tools
- MySQL 8 and MySQL Workbench
- SQL: joins, subqueries, `GROUP BY` / `HAVING`, `CASE`, date functions, `EXISTS`

## Database
7 tables, loaded from CSV files.

| Table | Rows | Description |
|---|---|---|
| branches | 40 | Branch details and region |
| customers | 500 | Customer profile, segment, KYC status |
| accounts | 700 | Accounts linked to customers and branches |
| cards | 600 | Cards linked to accounts |
| transactions | 5,000 | Account transactions |
| loans | 300 | Loans linked to customers and branches |
| loan_payments | 2,000 | Loan repayment records |

Relationships: customers and branches have many accounts and loans. Accounts have many cards and transactions. Loans have many payments.

## Project structure
1. **Sprint 1:** read the ER diagram and plan the analysis (no SQL)
2. **Sprint 2:** create the tables and import the data
3. **Sprint 3:** 10 basic queries
4. **Sprint 4:** objective-based analysis
   - 4.1 Customer profile and segmentation
   - 4.2 Account usage and branch activity
   - 4.3 Transaction patterns
   - 4.4 Loan performance and repayment
   - 4.5 Card usage and product engagement

All queries are in `Retail_Banking.sql`, with comments explaining each one. The findings, conclusions and recommendations are at the end of the file.

## A data issue I solved
Importing `accounts.csv` with the Import Wizard loaded only 203 of 700 rows, because active accounts have a blank `close_date`. I fixed it by loading the file into a text-only staging table, then copying it into the real table with `NULLIF(column, '')` to turn blanks into NULL.

## Key findings
- **Loan risk is the biggest problem.** 56% of loans are Defaulted or In Arrears, and they hold about 73% of the 53.4 million outstanding balance. 25% of loan payments are late.
- **Only 33.8% of transactions are completed.** The rest are pending (33.7%) or failed (32.6%).
- **Digital channels carry about half of all transactions.** Online and Mobile together make up 49.9%.
- **Customer segments do not match customer value.** Average income and credit score are almost the same across segments.
- **KYC has gaps.** 241 active customers have only Partial or Pending KYC.
- **Most cards are unused.** 93.8% of cards are inactive.
- **Cross-selling has room to grow.** Only 24.8% of customers use an account, a card and a loan together.

## Recommendations
1. Set up a recovery team for defaulted loans and loans past maturity.
2. Investigate the causes of failed and pending transactions.
3. Invest in Online and Mobile channels.
4. Rebuild customer segments using income and credit score.
5. Run a KYC completion drive and a card activation campaign.
6. Cross-sell to customers who hold one product or none.

## How to run
1. Create the database and tables with the first part of `Retail_Banking.sql`.
2. Import the CSV files in this order: branches, customers, accounts, cards, transactions, loans, loan_payments.
3. Run the Sprint 3 and Sprint 4 queries one at a time (Ctrl + Enter in Workbench).
