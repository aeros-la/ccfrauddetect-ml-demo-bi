# The name of this view in Looker is "Predictions View"
view: predictions_view {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `fraud_detection.predictions_view`
    ;;
  # No primary key is defined for this view. In order to join this view in an Explore,
  # define primary_key: yes on a dimension that has no repeated values.

  # Here's what a typical dimension looks like in LookML.
  # A dimension is a groupable field that can be used to filter query results.
  # This dimension will be called "Age" in Explore.

  dimension: age {
    type: number
    sql: ${TABLE}.age ;;
  }

  # A measure is a field that uses a SQL aggregate function. Here are defined sum and average
  # measures for this dimension, but you can also add measures of many different aggregates.
  # Click on the type parameter to see all the options in the Quick Help panel on the right.

  measure: total_age {
    type: sum
    sql: ${age} ;;
  }

  measure: sum_amt {
    type: sum
    sql: ${amt} ;;
  }

  measure: average_age {
    type: average
    sql: ${age} ;;
  }

  measure: average_fraud {
    type: average
    sql:(
    SELECT (SELECT COUNT(*) FROM `aeros-ccfrauddetect-ml-demo.fraud_detection.predictions_view` WHERE predicted_is_fraud = 1)/COUNT(*) * 100
    FROM `aeros-ccfrauddetect-ml-demo.fraud_detection.predictions_view` );;
  }

  dimension: amt {
    type: number
    sql: ${TABLE}.amt ;;
  }

  dimension: avg_spend_pm {
    type: number
    sql: ${TABLE}.avg_spend_pm ;;
  }

  dimension: avg_spend_pw {
    type: number
    sql: ${TABLE}.avg_spend_pw ;;
  }

  dimension: category {
    type: string
    sql: ${TABLE}.category ;;
  }

  dimension: cc_num {
    type: number
    sql: ${TABLE}.cc_num ;;
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
  }

  dimension: city_pop {
    type: number
    sql: ${TABLE}.city_pop ;;
  }

  dimension: day {
    type: number
    sql: ${TABLE}.day ;;
  }

  dimension: distance {
    type: number
    sql: ${TABLE}.distance ;;
  }

  dimension: first {
    type: string
    sql: ${TABLE}.first ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: job {
    type: string
    sql: ${TABLE}.job ;;
  }

  dimension: last {
    type: string
    sql: ${TABLE}.last ;;
  }

  dimension: lat {
    type: number
    sql: ${TABLE}.lat ;;
  }

  dimension: long {
    type: number
    sql: ${TABLE}.long ;;
  }

  dimension: location {
    type: location
    sql_latitude: ${TABLE}.lat ;;
    sql_longitude: ${TABLE}.long ;;
  }

  dimension: merchant {
    type: string
    sql: ${TABLE}.merchant ;;
  }

  dimension: predicted_is_fraud {
    type: number
    sql: ${TABLE}.predicted_is_fraud ;;
  }

  # This field is hidden, which means it will not show up in Explore.
  # If you want this field to be displayed, remove "hidden: yes".

  dimension: predicted_is_fraud_probs {
    hidden: yes
    sql: ${TABLE}.predicted_is_fraud_probs ;;
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
  }

  dimension: street {
    type: string
    sql: ${TABLE}.street ;;
  }

  dimension: trans_diff {
    type: number
    sql: ${TABLE}.trans_diff ;;
  }

  dimension: trans_freq_24 {
    type: number
    sql: ${TABLE}.trans_freq_24 ;;
  }

  dimension: unix_time {
    type: number
    sql: ${TABLE}.unix_time ;;
  }

  dimension: date {
    type: date
    sql:(
      SELECT DATE(format_timestamp("%Y-%m-%d", timestamp_seconds(${unix_time})))
      );;
  }

  dimension: zip {
    type: zipcode
    sql: ${TABLE}.zip ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }
}

# The name of this view in Looker is "Predictions View Predicted Is Fraud Probs"
view: predictions_view__predicted_is_fraud_probs {
  # No primary key is defined for this view. In order to join this view in an Explore,
  # define primary_key: yes on a dimension that has no repeated values.

  # Here's what a typical dimension looks like in LookML.
  # A dimension is a groupable field that can be used to filter query results.
  # This dimension will be called "Label" in Explore.

  dimension: label {
    type: number
    sql: label ;;
  }

  # A measure is a field that uses a SQL aggregate function. Here are defined sum and average
  # measures for this dimension, but you can also add measures of many different aggregates.
  # Click on the type parameter to see all the options in the Quick Help panel on the right.

  measure: total_label {
    type: sum
    sql: ${label} ;;
  }

  measure: average_label {
    type: average
    sql: ${label} ;;
  }

  # This field is hidden, which means it will not show up in Explore.
  # If you want this field to be displayed, remove "hidden: yes".

  dimension: predictions_view__predicted_is_fraud_probs {
    type: string
    hidden: yes
    sql: predictions_view__predicted_is_fraud_probs ;;
  }

  dimension: prob {
    type: number
    sql: prob ;;
  }
}
