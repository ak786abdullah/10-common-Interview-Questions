create database A_Company;

USE A_Company;

-- --------------------------------------------------------------
-- SETUP: Employees Table
-- --------------------------------------------------------------

CREATE TABLE Employees (
     id INT PRIMARY KEY,
     name VARCHAR(50),
     salary INT,
     departmentId INT,
     managerId INT);
     
INSERT INTO Employees (id, name, salary, departmentId, managerId) VALUES
 (1, 'Joe', 70000, 1, 3),   -- Earns more than manager (Sam)
 (2, 'Henry', 80000, 2, 4), -- Earns less than manager (Max)
 (3, 'Sam', 60000, 1, NULL),-- Manager of Dept 1
 (4, 'Max', 90000, 2, NULL),-- Manager of Dept 2
 (5, 'Janet', 69000, 1, 3),
 (6, 'Randy', 85000, 1, 3), -- Highest in Dept 1
 (7, 'Will', 70000, 1, 3);
 
 
 -- ==================================================================
-- Find the Second Highest Distinct Salary
-- ===================================================================

SELECT distinct salary
from employees 
order by salary desc
limit 1 offset 1; 


-- =======================================================================
-- Find Employees Who Earn More Than Their Direct Managers
-- =======================================================================

select e.name as high_salary_employee, m.name as manager from employees e
join employees m 
on e.managerID=m.id 
where e.salary > m.salary ;


-- ------------------------------------------------------------------
-- SETUP: Logins Table
-- ------------------------------------------------------------------

CREATE TABLE Logins (
    user_id INT,
    login_date DATE
);

INSERT INTO Logins (user_id, login_date) VALUES
(1, '2024-01-01'),
(1, '2024-01-02'),
(1, '2024-01-03'), -- 3rd consecutive day
(1, '2024-01-04'),
(2, '2024-01-01'),
(2, '2024-01-03'), -- Skipped a day
(2, '2024-01-04');


-- ================================================================================
-- Identify Users Who Logged In for 3 or More Consecutive Days 
-- the distance  between days =1
-- =================================================================================

SELECT distinct user_id 
from (
 select user_id ,
login_date,
lag(login_date,1) over (partition by user_id order by login_date) as prev_day_1,
lag(login_date,2) over (partition by user_id order by login_date ) as prev_day_2 FROM logins) as date_histary
where datediff(login_date,prev_day_1)=1
AND datediff(prev_day_1,prev_day_2)=1; 
 
-- ------------------------------------------------------------------
-- SETUP: Orders Table
-- ------------------------------------------------------------------
 
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    amount INT
);

INSERT INTO Orders (order_id, customer_id, order_date, amount) VALUES
(1, 101, '2024-01-10', 100),
(2, 101, '2024-01-15', 100),
(3, 101, '2024-02-20', 100), -- 3rd order
(4, 101, '2024-03-05', 100),
(5, 101, '2024-05-01', 100),
(6, 101, '2024-06-15', 100), -- 6th order (Target for Q9)
(7, 102, '2024-01-10', 500),
(8, 102, '2024-02-15', 600); -- Growth calculation data (Q4)


-- ====================================================================================
-- Calculate Month-Over-Month Percentage Growth?

-- data is given daily sale 
-- step 1.  we need monthly sale 
-- step 2.  prev_month_sale for  growth formula 
-- =========================================================================================

-- step 1.  we need monthly sale

with monthly_sale as (
SELECT date_format(order_date,"%Y-%m") as order_month,
sum(amount) as total_sale 
FROM Orders
group by order_month),

-- Step 2: Use the LAG() window function to retrieve the
--  previous month's sales alongside current sales to 
-- calculate the percentage growth.

monthly_sale_with_prev_month_sale as( 
SELECT order_month,
total_sale,
lag(total_sale,1) over (order by order_month) as prev_sale from monthly_sale
)

select *,round(((total_sale-prev_sale ) / nullif(prev_sale,0) * 100),2) as monthly_growth
from monthly_sale_with_prev_month_sale;

-- ===========================================================================
-- Find Customer IDs with > 5 Orders in 2024
-- ===========================================================================

SELECT customer_id from orders
where year(order_date)=2024 
group by customer_id 
having count(customer_id)>5;
select * from orders;

-- ------------------------------------------------------------------
-- SETUP: Transactions Table
-- ------------------------------------------------------------------

CREATE TABLE Transactions (
    transaction_id INT,
    user_id INT,
    transaction_date DATE,
    amount INT
);

INSERT INTO Transactions (transaction_id, user_id, transaction_date, amount) VALUES
(1, 1, '2024-01-01', 100),
(2, 1, '2024-01-02', 150),
(3, 2, '2024-01-02', 200),
(4, 3, '2024-01-03', 300),
(5, 3, '2024-01-04', 100), -- User 3 has 2 txns (for Q7 distribution)
(6, 1, '2024-01-05', 50),
(7, 1, '2024-01-06', 50),
(8, 1, '2024-01-07', 50),
(9, 1, '2024-01-08', 50); -- Enough dates for rolling avg 



-- ==============================================================================================
--  Get Distribution of Users by Transaction Count
-- (A spacific_transaction how many user made) 
-- =================================================================================================

-- step 1.  Calculate how many transactions each user made 

with user_count as (
SELECT user_id, count(transaction_id) as total_transaction
from transactions group by user_id
) 

-- step 2.  Group by that count to find the distribution

SELECT total_transaction as number_of_transactions ,
count(user_id) as number_of_user 
from user_count 
group by total_transaction 
order by total_transaction ;

-- =========================================================================
-- Calculate a 7-Day Rolling Average
-- In a day thousand of transaction made so,
-- we first calculate daily_volume 
-- ==========================================================================

-- step 1. daily_volume  

with daily_volume as (
SELECT DATE_FORMAT(transaction_date ,"%y-%m-%d") as daily_transaction,
sum(amount) as daily_total
FROM transactions
group by daily_transaction )

-- step 2. 7_day_rolling_avg

SELECT daily_transaction, daily_total,
AVG(daily_total) over (order by daily_transaction rows between 6 preceding and current row ) as 7_day_avg from daily_volume;


-- ------------------------------------------------------------------
-- SETUP: Person Table (Duplicates)
-- ------------------------------------------------------------------

CREATE TABLE Person (
    id INT PRIMARY KEY,
    email VARCHAR(100)
);

INSERT INTO Person (id, email) VALUES
(1, 'john@example.com'),
(2, 'bob@example.com'),
(3, 'john@example.com'); -- Duplicate of ID 1


-- ===========================================================================================
-- Delete Duplicate Emails (Keep Smallest ID)
-- ===========================================================================================

-- step 1.
set SQL_SAFE_UPDATES=0;

-- method 1:

-- with duplicates as (
--  SELECT email, row_number() over (partition by email
--   order by id ) as row_numbers 
--   from person
--  )
--  -- step 2. delete duplicates
--   delete from duplicates 
--   where row_numbers > 1;

-- Note: MySQL does not allow updates/deletes directly 
-- on CTEs. Therefore, I used a Self-Join method to identify and remove duplicates
--  while keeping the record with the lowest ID.

-- method 2 :

--  self join method 

delete p1
from person p1
join person p2 
on p1.email=p2.email
where P1.id > p2.id;

-- ------------------------------------------------------------------
-- SETUP: Signups and Activity
-- ------------------------------------------------------------------

CREATE TABLE Signups (
    user_id INT PRIMARY KEY,
    signup_date DATE
);

CREATE TABLE Activity (
    user_id INT,
    activity_date DATE
);

INSERT INTO Signups (user_id, signup_date) VALUES
(1, '2024-01-01'),
(2, '2024-01-15'),
(3, '2024-02-01');

INSERT INTO Activity (user_id, activity_date) VALUES
(1, '2024-01-05'), -- Retained
(1, '2024-01-20'),
(3, '2024-02-10'); -- Retained (User 2 is churned/not retained) 



-- ============================================================================================
-- Calculate User Retention Rate by Sign-up Month 
-- ============================================================================================

SELECT 
    -- 1. Create the Cohort (Group by Signup Month)
    DATE_FORMAT(s.signup_date, '%Y-%m') AS signup_month,
    
    -- 2. Calculate Total Users (The Denominator)
    COUNT(DISTINCT s.user_id) AS total_signups,
    
    -- 3. Calculate Retained Users (The Numerator)
    COUNT(DISTINCT a.user_id) AS retained_users,
    
    -- 4. The Math: Retained / Total
    ROUND(COUNT(DISTINCT a.user_id) / COUNT(DISTINCT s.user_id), 2) AS retention_rate

FROM Signups s
LEFT JOIN Activity a 
    ON s.user_id = a.user_id 
    -- DEFINITION OF RETENTION:
    -- Did they log in between 1 day and 30 days AFTER signing up?
    AND DATEDIFF(a.activity_date, s.signup_date) BETWEEN 1 AND 30

GROUP BY signup_month;

-- ------------------------------------------------------------------
-- SETUP: EmployeeSalaries
-- ------------------------------------------------------------------

CREATE TABLE EmployeeSalaries (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    salary INT,
    departmentId INT
);

-- Insert Data
INSERT INTO EmployeeSalaries (id, name, salary, departmentId) VALUES
-- Department 1 (IT)
(1, 'Alice', 90000, 1), 
(2, 'Bob',   85000, 1),  
(3, 'Charlie', 85000, 1),
(4, 'David', 70000, 1),  
(5, 'Eve',   60000, 1), 

-- Department 2 (HR)
(6, 'Frank', 80000, 2),  
(7, 'Grace', 75000, 2);  

-

-- ========================================================================================
-- Top 3 Highest Earners in Each Department 
-- =======================================================================================

-- step 1. rank salary of each deparment 

 with salary_rank as (
SELECT id,name,departmentid,salary,dense_rank() over (partition by departmentID
order by salary desc) as rank_no 
from employeesalaries
) 

-- step 2. select 3 highest salary 

SELECT name,departmentid,salary,rank_no 
from salary_rank 
where rank_no <= 3;

