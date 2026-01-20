WITH users_paying AS (
  SELECT
    ua.time :: date as date,
    COUNT(DISTINCT user_id) FILTER (
      WHERE
        action = 'create_order'
        AND order_id NOT IN(
          SELECT
            order_id
          FROM
            user_actions
          WHERE
            action = 'cancel_order'
        )
    ) as paying_users
  FROM
    user_actions ua
  GROUP BY
    ua.time :: date
  ORDER BY
    ua.time :: date
),
couriers_delivering AS(
  SELECT
    ca.time :: date as date,
    COUNT(DISTINCT courier_id) FILTER (
      WHERE
        (
          action = 'accept_order'
          OR action = 'deliver_order'
        )
        AND order_id IN(
          SELECT
            order_id
          FROM
            courier_actions
          WHERE
            action = 'deliver_order'
        )
    ) active_couriers
  FROM
    courier_actions ca
  GROUP BY
    ca.time :: date
  ORDER BY
    ca.time :: date
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
  up.date as date,
  ROUND(up.paying_users :: decimal / cd.active_couriers, 2) users_per_courier,
  ROUND(oo.orders :: decimal / cd.active_couriers, 2) orders_per_courier
FROM
  users_paying up
  JOIN couriers_delivering cd USING(date)
  JOIN overall_orders oo USING(date)
ORDER BY
  up.date