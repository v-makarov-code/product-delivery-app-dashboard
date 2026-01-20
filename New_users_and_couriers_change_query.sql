WITH new_users AS (
  SELECT
    first_day as day,
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
    day
),
new_couriers AS (
  SELECT
    first_day as day,
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
    day
),
new_change AS (
  SELECT
    nu.day :: date as date,
    nu.new_users,
    nc.new_couriers,
    SUM(nu.new_users) OVER w :: int as total_users,
    SUM(nc.new_couriers) OVER w :: int as total_couriers,
    ROUND(
      (nu.new_users - LAG(nu.new_users) OVER w) :: DECIMAL / LAG(nu.new_users) OVER w * 100,
      2
    ) as new_users_change,
    ROUND(
      (
        nc.new_couriers - LAG(nc.new_couriers) OVER w :: DECIMAL
      ) / LAG(nc.new_couriers) OVER w * 100,
      2
    ) as new_couriers_change
  FROM
    new_users nu
    JOIN new_couriers nc ON nu.day = nc.day WINDOW w AS (
      ORDER BY
        nu.day
    )
)
SELECT
  new_change.*,
  ROUND(
    (total_users - LAG(total_users) OVER w :: DECIMAL) / LAG(total_users) OVER w * 100,
    2
  ) total_users_growth,
  ROUND(
    (
      total_couriers - LAG(total_couriers) OVER w :: DECIMAL
    ) / LAG(total_couriers) OVER w * 100,
    2
  ) total_couriers_growth
FROM
  new_change WINDOW w AS (
    ORDER BY
      date
  )