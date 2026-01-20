WITH new_users AS (
  SELECT
    first_day as date,
    COUNT(user_id) as new_users
  FROM
    (
      SELECT
        user_id,
        DATE_TRUNC('day', MIN(time)) as first_day
      FROM
        user_actions
      GROUP BY
        user_id
    ) min_day
  GROUP BY
    first_day
  ORDER BY
    date
),
new_couriers AS (
  SELECT
    first_day as date,
    COUNT(courier_id) as new_couriers
  FROM
    (
      SELECT
        courier_id,
        DATE_TRUNC('day', MIN(time)) as first_day
      FROM
        courier_actions
      GROUP BY
        courier_id
    ) min_day
  GROUP BY
    first_day
  ORDER BY
    date
),
users_paying AS (
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
    ) as paying_users,
    SUM(nu.new_users) OVER(
      ORDER BY
        time :: date
    ) AS total_users
  FROM
    user_actions ua
    JOIN new_users nu ON ua.time :: date = nu.date
  GROUP BY
    ua.time :: date,
    nu.new_users
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
    ) active_couriers,
    SUM(nc.new_couriers) OVER(
      ORDER BY
        time :: date
    ) as total_couriers
  FROM
    courier_actions ca
    JOIN new_couriers nc ON ca.time :: date = nc.date
  GROUP BY
    ca.time :: date,
    nc.new_couriers
  ORDER BY
    ca.time :: date
)
SELECT
  up.date,
  up.paying_users,
  cd.active_couriers,
  ROUND(up.paying_users / up.total_users * 100, 2) paying_users_share,
  ROUND(cd.active_couriers / cd.total_couriers * 100, 2) active_couriers_share
FROM
  users_paying up
  JOIN couriers_delivering cd ON up.date = cd.date