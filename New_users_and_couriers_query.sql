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
)
SELECT
  nu.day :: date as date,
  nu.new_users,
  nc.new_couriers,
  SUM(nu.new_users) OVER(
    ORDER BY
      nu.day
  ) :: int as total_users,
  SUM(nc.new_couriers) OVER(
    ORDER BY
      nu.day
  ) :: int as total_couriers
FROM
  new_users nu
  JOIN new_couriers nc ON nu.day = nc.day