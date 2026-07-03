WITH sessions_info AS (
  SELECT 
    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS user_session_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    PARSE_DATE('%Y%m%d', event_date) AS session_date,
    geo.country AS country,
    device.category AS device_category,
    device.operating_system AS device_os,
    device.language AS device_language,
    traffic_source.name AS campaign,
    traffic_source.medium AS medium,
    traffic_source.source AS source,
    REGEXP_EXTRACT((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), r'(?:https:\/\/)?[^\/]+\/(.*)') AS landing_page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'session_start'
),

events AS (
  SELECT
    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS user_session_id,
    event_name,
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp_formatted,
    IFNULL(ecommerce.purchase_revenue_in_usd, 0) AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN ('session_start', 'view_item', 'add_to_cart', 'begin_checkout', 'add_shipping_info', 'add_payment_info', 'purchase')
)

SELECT 
  s.user_session_id,
  s.session_date,
  s.country,
  s.device_category,
  s.device_os,
  s.device_language,
  s.campaign,
  s.medium,
  s.source,
  s.landing_page_location,
  e.event_name,
  e.event_timestamp_formatted,
  IFNULL(e.revenue, 0) AS revenue
FROM sessions_info s
INNER JOIN events e USING(user_session_id)
