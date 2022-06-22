# The name of this view in Looker is "Pubsub"
view: pubsub {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `fraud_detection.pubsub`
    ;;
  # No primary key is defined for this view. In order to join this view in an Explore,
  # define primary_key: yes on a dimension that has no repeated values.

  # Here's what a typical dimension looks like in LookML.
  # A dimension is a groupable field that can be used to filter query results.
  # This dimension will be called "Amt" in Explore.

  dimension: amt {
    type: number
    sql: ${TABLE}.amt ;;
  }

  # A measure is a field that uses a SQL aggregate function. Here are defined sum and average
  # measures for this dimension, but you can also add measures of many different aggregates.
  # Click on the type parameter to see all the options in the Quick Help panel on the right.

  measure: total_amt {
    type: sum
    sql: ${amt} ;;
  }

  measure: average_amt {
    type: average
    sql: ${amt} ;;
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

  # Dates and timestamps can be represented in Looker using a dimension group of type: time.
  # Looker converts dates and timestamps to the specified timeframes within the dimension group.

  dimension_group: dob {
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.dob ;;
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

  dimension: merch_lat {
    type: number
    sql: ${TABLE}.merch_lat ;;
  }

  dimension: merch_long {
    type: number
    sql: ${TABLE}.merch_long ;;
  }

  dimension: merchant {
    type: string
    sql: ${TABLE}.merchant ;;
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
  }

  dimension: street {
    type: string
    sql: ${TABLE}.street ;;
  }

  dimension: trans_date_trans_time {
    type: string
    sql: ${TABLE}.trans_date_trans_time ;;
  }

  dimension: trans_num {
    type: string
    sql: ${TABLE}.trans_num ;;
  }

  dimension: unix_time {
    type: number
    sql: ${TABLE}.unix_time ;;
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
