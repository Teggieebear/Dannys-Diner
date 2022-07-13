-- Creating the sales table

CREATE TABLE sales (
   customer_id VARCHAR (1),
   order_date  DATE,
   product_id  INTEGER,
   );

   INSERT INTO sales
        (customer_id, order_date, product_id)
   VALUES
        ('A', '2021-01-01', '1'),
		('A', '2021-01-01', '2'),
        ('A', '2021-01-07', '2'),
		('A', '2021-01-10', '3'),
	    ('A', '2021-01-11', '3'),
	    ('A', '2021-01-11', '3'),
	    ('B', '2021-01-01', '2'),
	    ('B', '2021-01-02', '2'),
	    ('B', '2021-01-04', '1'),
	    ('B', '2021-01-11', '1'),
	    ('B', '2021-01-16', '3'),
	    ('B', '2021-02-01', '3'),
		('C', '2021-01-01', '3'),
	    ('C', '2021-01-01', '3'),
	    ('C', '2021-01-07', '3');
		

--Creating the menu table

CREATE TABLE menu(
	product_id  INTEGER,
	product_name VARCHAR (5),
		  price  INTEGER);

	INSERT INTO menu
		(product_id, product_name, price)
	VALUES 
		('1', 'sushi', '10'),
	    ('2', 'curry', '15'),
		('3', 'ramen', '12');
		

--Creating the members table

	
CREATE TABLE members (
   customer_id VARCHAR(1),
   join_date  DATE);

	INSERT INTO members
		(customer_id, join_date)
	VALUES
		('A', '2021-01-07'),
		('B', '2021-01-09');


-- (1) What is the total amount each customer spent at the restaurant?
	SELECT customer_id, sum(price) as total_price 
	  FROM menu
	  JOIN sales ON menu.product_id = sales.product_id
	  GROUP BY customer_id;

 -- (2) How many days has each customer visited the restaurant?
	  SELECT customer_id, COUNT(DISTINCT ( order_date)) as days_visited 
	    FROM sales
	  Group by customer_id;

 -- (3) What was the first item from the menu purchased by each customer?
	WITH first_purchase_CTE AS
		(SELECT customer_id, order_date, product_name,
		DENSE_RANK() OVER (PARTITION BY sales.customer_id
		ORDER BY sales.order_date) AS first_purchase 
		FROM sales
		JOIN menu ON sales.product_id = menu.product_id)
			SELECT customer_id, product_name
			FROM first_purchase_CTE 
			WHERE first_purchase = 1
			GROUP BY customer_id, product_name;
	
 -- (4) What is the most purchased item on the menu and how many times was it purchased by all customers?
	SELECT TOP 1 (COUNT(menu.product_name)) AS order_count, product_name, sales.product_id
	FROM sales 
	JOIN menu ON sales.product_id = menu.product_id
	GROUP BY sales.product_id, menu.product_name
	ORDER BY sales.product_id desc;

  -- (5) Which item was the most popular for each customer
	 WITH most_popular_CTE AS
	 (SELECT customer_id, product_name, COUNT(product_name) AS product_count,
			DENSE_RANK() OVER (PARTITION BY sales.customer_id
			ORDER BY  menu.product_name) AS rank
			FROM sales
			JOIN menu ON sales.product_id = menu.product_id
			GROUP BY sales.customer_id, menu.product_name)
				SELECT customer_id, product_name, product_count
				FROM most_popular_CTE 
				WHERE rank = 1
				ORDER BY customer_id, product_count DESC;


-- (6) Which item was purchased first by the customer after they became a member?
	WITH member_sales_cte AS 
	(SELECT sales.customer_id, join_date, order_date, product_id,
     DENSE_RANK() OVER(PARTITION BY sales.customer_id
	 ORDER BY order_date) AS rank
     FROM sales 
     JOIN members ON sales.customer_id = members.customer_id
	WHERE order_date >= join_date)
		SELECT member_sales_cte.customer_id, member_sales_cte.product_id, menu.product_name
		FROM member_sales_cte 
		JOIN menu ON  member_sales_cte.product_id = menu.product_id
		WHERE rank = 1;

-- (7) Which item was purchased just before the customer became a member?
	WITH prior_member_CTE AS 
	(SELECT sales.customer_id, join_date, order_date, product_id,
     DENSE_RANK() OVER(PARTITION BY sales.customer_id
	 ORDER BY order_date) AS rank
     FROM sales 
     JOIN members ON sales.customer_id = members.customer_id
	WHERE order_date < join_date)
		SELECT prior_member_CTE.customer_id, prior_member_CTE.product_id, menu.product_name
		FROM prior_member_CTE 
		JOIN menu ON  prior_member_CTE.product_id = menu.product_id
		WHERE rank = 1;

--(8) What is the total items and amount spent for each member before they became a member?
	WITH total_price_CTE AS 
	(SELECT sales.customer_id, join_date, order_date, product_id,
     DENSE_RANK() OVER(PARTITION BY sales.customer_id
	 ORDER BY order_date) AS rank
     FROM sales 
     JOIN members ON sales.customer_id = members.customer_id
	WHERE order_date < join_date)
	SELECT total_price_CTE.customer_id, COUNT(DISTINCT(menu.product_name)) AS Total_item, SUM(menu.price) AS total_amount
	FROM total_price_CTE
	JOIN menu ON total_price_CTE.product_id = menu.product_id
	GROUP BY customer_id;
	
-- (9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?
	WITH multiplier_CTE AS
	(SELECT *, 
		CASE
		WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10
		END AS points
		FROM menu)
			SELECT customer_id, SUM(points) AS total_points
			FROM multiplier_CTE
			JOIN sales ON multiplier_CTE.product_id = sales.product_id
			GROUP BY customer_id;

-- (10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?
	WITH date_cte AS 
	(SELECT *, 
	 DATEADD(DAY, 6, join_date) AS valid_till, 
	EOMONTH('2021-01-31') AS last_date
	FROM members)
	SELECT date_cte.customer_id, order_date, join_date, 
	valid_till, last_date, product_name, price,
	SUM(CASE
	WHEN product_name = 'sushi' THEN 2 * 10 * price
	WHEN order_date BETWEEN join_date AND valid_till THEN 2 * 10 * price
	ELSE 10 * price
	END) AS points
	FROM date_cte 
	JOIN sales ON date_cte.customer_id = sales.customer_id
    JOIN menu
    ON sales.product_id = menu.product_id
    WHERE order_date < last_date
    GROUP BY date_CTE.customer_id, order_date, join_date, valid_till, last_date, product_name, price

-- Bonus (JOIN)
	SELECT sales.customer_id, order_date, product_name, price,
	CASE
	WHEN order_date >= join_date THEN 'Y'
	ELSE 'N'
	END as member
	FROM sales  
	JOIN menu  ON sales.product_id = menu.product_id
	JOIN members ON sales.customer_id = members.customer_id
	ORDER BY customer_id, order_date, price DESC;

-- Bonus (Rank)
	WITH rank_CTE AS 
	(SELECT sales.customer_id, order_date, product_name, price,
	CASE
	WHEN join_date <= order_date THEN 'Y'
	ELSE 'N' END AS member
   FROM sales
   JOIN menu ON sales.product_id = menu.product_id
   JOIN members AS ON sales.customer_id = members.customer_id 
   SELECT *, 
   CASE
   WHEN member = 'N' then NULL
   ELSE RANK () OVER(PARTITION BY customer_id, member
   ORDER BY order_date) END AS ranking
    FROM rank_CTE;


	 