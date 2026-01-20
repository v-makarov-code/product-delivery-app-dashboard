SELECT
  date,
  ROUND(AVG(time_diff / 60)) :: int as minutes_to_deliver
FROM(
    SELECT
      courier_id,
      order_id,
      time :: date AS date,
      EXTRACT(
        epoch
        FROM
          time - LAG(time, 1) OVER w
      ) AS time_diff
    FROM
      courier_actions
    WHERE
      order_id NOT IN (
        SELECT
          order_id
        FROM
          user_actions
        WHERE
          action = 'cancel_order'
      ) WINDOW w AS(
        PARTITION BY courier_id,
        order_id
        ORDER BY
          time
      )
  ) t1
WHERE
  time_diff IS NOT NULL
GROUP BY
  date
ORDER BY
  date