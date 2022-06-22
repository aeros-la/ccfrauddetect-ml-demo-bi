# Define the database connection to be used for this model.
connection: "ccfrauddetect-connection"

# include all the views
include: "/views/**/*.view"

# Datagroups define a caching policy for an Explore. To learn more,
# use the Quick Help panel on the right to see documentation.

datagroup: ccfrauddetect_ml_demo_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: ccfrauddetect_ml_demo_default_datagroup

# Explores allow you to join together different views (database tables) based on the
# relationships between fields. By joining a view into an Explore, you make those
# fields available to users for data analysis.
# Explores should be purpose-built for specific use cases.

# To see the Explore you’re building, navigate to the Explore menu and select an Explore under "Ccfrauddetect-ml-demo"

# To create more sophisticated Explores that involve multiple views, you can use the join parameter.
# Typically, join parameters require that you define the join type, join relationship, and a sql_on clause.
# Each joined view also needs to define a primary key.

explore: testing {}

explore: training {}

explore: predictions_view {
  join: predictions_view__predicted_is_fraud_probs {
    view_label: "Predictions View: Predicted Is Fraud Probs"
    sql: LEFT JOIN UNNEST(${predictions_view.predicted_is_fraud_probs}) as predictions_view__predicted_is_fraud_probs ;;
    relationship: one_to_many
  }
}

explore: test_w_aggregates_view {}

explore: pubsub_error_records {
  join: pubsub_error_records__attributes {
    view_label: "Pubsub Error Records: Attributes"
    sql: LEFT JOIN UNNEST(${pubsub_error_records.attributes}) as pubsub_error_records__attributes ;;
    relationship: one_to_many
  }
}

explore: train_w_aggregates_view {}

explore: pubsub {}
