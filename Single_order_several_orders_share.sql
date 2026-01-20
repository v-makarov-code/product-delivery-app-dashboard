WITH active_users AS(
  SELECT
    user_id,
    action,
    order_id,
    time :: date as date
  FROM
    user_actions
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
)
SELECT
  date,
  ROUND(
    COUNT(user_id) FILTER (
      WHERE
        order_count = 1
    ) / COUNT(user_id) :: decimal * 100,
    2
  ) as single_order_users_share,
  ROUND(
    COUNT(user_id) FILTER (
      WHERE
        order_count > 1
    ) / COUNT(user_id) :: decimal * 100,
    2
  ) as several_orders_users_share
FROM(
    SELECT
      user_id,
      date,
      COUNT(order_id) order_count
    FROM
      active_users
    GROUP BY
      user_id,
      date
  ) t1
GROUP BY
  date
ORDER BY
  date