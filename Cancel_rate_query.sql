WITH successful_orders AS(
  SELECT
    DATE_PART('hour', creation_time) :: INT as hour,
    COUNT(order_id) as successful_orders
  FROM
    orders
  WHERE
    order_id IN (
      SELECT
        order_id
      FROM
        courier_actions
      WHERE
        action = 'deliver_order'
    )
  GROUP BY
    DATE_PART('hour', creation_time)
  ORDER BY
    hour
),
canceled_orders AS (
  SELECT
    DATE_PART('hour', creation_time) :: INT as hour,
    COUNT(order_id) as canceled_orders
  FROM
    orders
  WHERE
    order_id IN (
      SELECT
        order_id
      FROM
        user_actions
      WHERE
        action = 'cancel_order'
    )
  GROUP BY
    DATE_PART('hour', creation_time)
  ORDER BY
    hour
)
SELECT
  so.hour,
  so.successful_orders,
  co.canceled_orders,
  ROUND(
    co.canceled_orders :: decimal /(so.successful_orders + co.canceled_orders),
    3
  ) cancel_rate
FROM
  successful_orders so
  JOIN canceled_orders co USING(hour)
ORDER BY
  so.hour