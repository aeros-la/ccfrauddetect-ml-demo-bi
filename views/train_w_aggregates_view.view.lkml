# The name of this view in Looker is "Train W Aggregates View"
view: train_w_aggregates_view {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `fraud_detection.train_w_aggregates_view`
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

  measure: average_age {
    type: average
    sql: ${age} ;;
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

  dimension: is_fraud {
    type: number
    sql: ${TABLE}.is_fraud ;;
  }

  dimension: job {
    type: string
    sql: ${TABLE}.job ;;
  }

  dimension: merchant {
    type: string
    sql: ${TABLE}.merchant ;;
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
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

  measure: count {
    type: count
    drill_fields: []
  }
}
