WITH first_day AS (
  SELECT
    user_id,
    DATE(MIN(time)) as first_day
  FROM
    user_actions
  GROUP BY
    user_id
),
first_day_1 AS (
  SELECT
    user_id,
    DATE(MIN(time)) as first_day
  FROM
    user_actions
  WHERE
    order_id NOT IN(
      SELECT
        order_id
      FROM
        user_actions
      WHERE
        action = 'cancel_order'
    )
  GROUP BY
    user_id
),
daily_first_orders AS (
  SELECT
    first_day AS date,
    COUNT(user_id) first_orders
  FROM
    first_day_1
  GROUP BY
    first_day
),
orders_per_user AS (
  SELECT
    user_id,
    time :: date AS date,
    COUNT(order_id) orders_this_day
  FROM
    user_actions
  WHERE
    order_id NOT IN(
      SELECT
        order_id
      FROM
        user_actions
      WHERE
        action = 'cancel_order'
    )
  GROUP BY
    user_id,
    time :: date
),
new_users_order_count AS(
  SELECT
    fd.first_day as date,
    SUM(COALESCE(opu.orders_this_day, 0)) orders_this_day
  FROM
    first_day fd
    LEFT JOIN orders_per_user opu ON fd.user_id = opu.user_id
    AND fd.first_day = opu.date
  GROUP BY
    fd.first_day
  ORDER BY
    date
),
overall_orders AS (
  SELECT
    time :: date as date,
    COUNT(order_id) as orders
  FROM
    user_actions
  WHERE
    order_id NOT IN(
      SELECT
        order_id
      FROM
        user_actions
      WHERE
        action = 'cancel_order'
    )
  GROUP BY
    time :: date
)
SELECT
  oo.date,
  oo.orders,
  dfo.first_orders,
  no.orders_this_day :: int as new_users_orders,
  ROUND(dfo.first_orders :: decimal / oo.orders * 100, 2) first_orders_share,
  ROUND(no.orders_this_day :: decimal / oo.orders * 100, 2) new_users_orders_share
FROM
  overall_orders oo
  JOIN daily_first_orders dfo ON oo.date = dfo.date
  JOIN new_users_order_count no ON oo.date = no.date
ORDER BY
  oo.date