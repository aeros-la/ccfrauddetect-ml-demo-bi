# Serverless Online ML & BI Modernization

Startup Day
Argentina 29/06/2022

<p align="center">
  <img src="https://github.com/aeros-la/ccfrauddetect-ml-demo-bi/blob/4ea55947c79e985b09e62bb9b5b4c81bf5ef4784/Startup%20Day%20Argentina.png">
</p>

# DataOps - Demo

Muchas de las organizaciones deciden hacer uso de sus datos y enfatizan en crear flujos de trabajo ML para solventar sus problemáticas, pero el proceso es tan complicado que puede causar varios problemas. Uno de los principales problemas se debe a la falta de un equipo de data scientist o data engineer, por lo que el proceso se torna demasiado difícil de crear.
Es por esto que se decide demostrar en la presente demo que con las herramientas utilizadas aquí, podemos generar soluciones escalables y efectivas solventando la problemática mencionada.

La presente solución se basa en la detección de fraude con tarjetas de crédito en tiempo real en donde se utilizan las siguientes herramientas serverless del ecosistema GCP:

- BigQuery
- BigQuery ML
- Dataflow
- Pub/Sub
- Looker

## Arquitectura propuesta

<p align="center">
  <img src="https://github.com/aeros-la/ccfrauddetect-ml-demo-bi/blob/4ea55947c79e985b09e62bb9b5b4c81bf5ef4784/architecture.png">
</p>

## Preparando los datos en BigQuery

En esta primera etapa, se recopilan datos históricos de [Kaggle](https://www.kaggle.com/datasets/kartik2112/fraud-detection?resource=download) de las transacciones con tarjetas de crédito como datos de training y testing, que seran almacenados en BigQuery

## Construyendo el modelo de detección de fraude usando BigQuery ML

### Preparación de los datos

Para que nuestro modelo obtenga una mejor performance, se realizan los siguientes features engineering a nuestros datos históricos y se crean una view para training y para testing:

#### Training data (train_w_aggregates_view)

```
(
SELECT  
    EXTRACT (dayofweek FROM trans_date_trans_time) AS day,
    DATE_DIFF(EXTRACT(DATE FROM trans_date_trans_time),dob, YEAR) AS age,
    ST_DISTANCE(ST_GEOGPOINT(long,lat), ST_GEOGPOINT(merch_long, merch_lat)) AS distance,
    TIMESTAMP_DIFF(trans_date_trans_time, last_txn_date , MINUTE) AS trans_diff, 
    AVG(amt) OVER(
                PARTITION BY cc_num
                ORDER BY unix_time
                -- 1 week is 604800 seconds
                RANGE BETWEEN 604800 PRECEDING AND 1 PRECEDING) AS avg_spend_pw,
    AVG(amt) OVER(
                PARTITION BY cc_num
                ORDER BY unix_time
                -- 1 month(30 days) is 2592000 seconds
                RANGE BETWEEN 2592000 PRECEDING AND 1 PRECEDING) AS avg_spend_pm,
    COUNT(*) OVER(
                PARTITION BY cc_num
                ORDER BY unix_time
                -- 1 day is 86400 seconds
                RANGE BETWEEN 86400 PRECEDING AND 1 PRECEDING ) AS trans_freq_24,
    category,
    amt,
    state,
    job,
    unix_time,
    city_pop,
    merchant,
    is_fraud
  FROM (
          SELECT t1.*,
              LAG(trans_date_trans_time) OVER (PARTITION BY t1.cc_num ORDER BY trans_date_trans_time ASC) AS last_txn_date,
          FROM  `aeros-ccfrauddetect-ml-demo.fraud_detection.training`  t1)
)
```

#### Testing data (test_w_aggregates_view)

```
(
WITH t1 as (
SELECT *, 'train' AS split FROM  `aeros-ccfrauddetect-ml-demo.fraud_detection.training` 
UNION ALL 
SELECT *, 'test' AS split FROM  `aeros-ccfrauddetect-ml-demo.fraud_detection.testing`
),
v2 AS (
  SELECT t1.*,
              LAG(trans_date_trans_time) OVER (PARTITION BY t1.cc_num ORDER BY trans_date_trans_time ASC) AS last_txn_date,
            FROM t1
),
v3 AS (
  SELECT
        EXTRACT (dayofweek FROM trans_date_trans_time) as day,
        DATE_DIFF(EXTRACT(DATE FROM trans_date_trans_time),dob, YEAR) AS age,
        ST_DISTANCE(ST_GEOGPOINT(long,lat), ST_GEOGPOINT(merch_long, merch_lat)) as distance,
        TIMESTAMP_DIFF(trans_date_trans_time, last_txn_date , MINUTE) AS trans_diff, 
        Avg(amt) OVER(
                    PARTITION BY cc_num
                    ORDER BY unix_time
                    RANGE BETWEEN 604800 PRECEDING AND 1 PRECEDING) AS avg_spend_pw,
        Avg(amt) OVER(
                    PARTITION BY cc_num
                    ORDER BY unix_time
                    RANGE BETWEEN 2592000 PRECEDING AND 1 PRECEDING) AS avg_spend_pm,
        count(*) OVER(
                    PARTITION BY cc_num
                    ORDER BY unix_time
                    RANGE BETWEEN 86400 PRECEDING AND 1 PRECEDING) AS trans_freq_24,
        category,
        amt,
        state,
        job,
        unix_time,
        city_pop,
        merchant,
        is_fraud,
        split
    FROM v2
)
SELECT * EXCEPT(split) FROM v3 WHERE split='test'

)
```

### Construcción del modelo
Una vez hayamos realizado los pasos descritos anteriormente, podemos entrenar un modelo usando SQL con BigQuery ML. Para la creación de nuestro modelo, optamos por utilizar un modelo de clasificación AutoML

```
CREATE OR REPLACE MODEL 
  `aeros-ccfrauddetect-ml-demo.fraud_detection.model_w_agg`
OPTIONS (
  MODEL_TYPE = 'AUTOML_CLASSIFIER',
  INPUT_LABEL_COLS = ["is_fraud"]
) AS
SELECT
  *
FROM 
  `aeros-ccfrauddetect-ml-demo.fraud_detection.train_w_aggregates_view`
```

### Evaluación del modelo

Para evaluar como performa nuestro modelo, hacemos uso de nuestra view previamente creada

```
SELECT
  "model_w_aggregates" AS model_name,
  *
FROM
  ML.EVALUATE(
    MODEL `aeros-ccfrauddetect-ml-demo.fraud_detection.model_w_agg`,
    (SELECT * FROM  `aeros-ccfrauddetect-ml-demo.fraud_detection.test_w_aggregates_view`))
```

## Configurar notificaciones de fraude basadas en alertas mediante Pub/Sub

Para el almacenamiento temporal de nuevas transacciones, se despliega un PubSub topic y subscription.
1. Vaya a PubSub console  y haga clic en Create Topic
2. En la ventana de diálogo, ingrese el topic ID y haga clic en Create Topic.
3. PubSub creará un nuevo tema y una nueva suscripción. Desplácese hacia abajo para verlo. Al mismo tiempo, puede crear una nueva suscripción usted mismo haciendo clic en Create Subscription.

## Conectar PubSub a BigQuery

Deberá crear un trabajo de Dataflow para exportar datos a una tabla de BigQuery. Para ello, habilita primero la API de Dataflow.
1. Vaya a APIs & Services dashboard.
2. Click Enable APIs and Services.
3. Busque la API de Dataflow mediante la barra de búsqueda y haga clic en Enable.
4. Una vez que la API de Dataflow esté habilitada, vuelve a tu topic de PubSub y haz clic en Export to BigQuery. 
5. Especifique los parámetros para crear un trabajo de Dataflow, en donde el template de Dataflow deberá ser PubSub Topic to BigQuery.

## Simulador de transacciones online

Para simular nuevas transacciones ejecutar Publisher_transactions/publisher.ipynb. Este se encargará de mandar transacciones de Publisher_transactions/transactions.dat a nuestro Topic de PubSub. (Asegurarse que los datos sean enviados al Topic de PubSub creado)

## Predicciones

Para predecir nuestras nuevas transacciones, se procede a crear la siguiente view (predictions_view) que será consumida por nuestro dashboard de Looker.

```
(
WITH
temp1 AS (
  SELECT t1.*,
              LAG(CAST (trans_date_trans_time AS TIMESTAMP)) OVER (PARTITION BY t1.cc_num ORDER BY CAST (trans_date_trans_time AS TIMESTAMP) ASC) AS last_txn_date,
            FROM `aeros-ccfrauddetect-ml-demo.fraud_detection.real_time_transactions` t1
),
temp2 AS (
  SELECT
        EXTRACT (dayofweek FROM CAST (trans_date_trans_time AS TIMESTAMP)) as day,
        DATE_DIFF(EXTRACT(DATE FROM CAST (trans_date_trans_time AS TIMESTAMP)),dob, YEAR) AS age,
        ST_DISTANCE(ST_GEOGPOINT(long,lat), ST_GEOGPOINT(merch_long, merch_lat)) as distance,
        TIMESTAMP_DIFF(CAST (trans_date_trans_time AS TIMESTAMP), last_txn_date , MINUTE) AS trans_diff, 
        Avg(amt) OVER(
                    PARTITION BY cc_num
                    ORDER BY unix_time
                    RANGE BETWEEN 604800 PRECEDING AND 1 PRECEDING) AS avg_spend_pw,
        Avg(amt) OVER(
                    PARTITION BY cc_num
                    ORDER BY unix_time
                    RANGE BETWEEN 2592000 PRECEDING AND 1 PRECEDING) AS avg_spend_pm,
        count(*) OVER(
                    PARTITION BY cc_num
                    ORDER BY unix_time
                    RANGE BETWEEN 86400 PRECEDING AND 1 PRECEDING) AS trans_freq_24,
        cc_num,
        first,
        last,
        gender,
        street,
        city,
        zip,
        lat,
        long,
        category,
        amt,
        state,
        job,
        unix_time,
        city_pop,
        merchant
    FROM temp1
),
predict AS(
SELECT
  *
FROM
  ML.PREDICT(
    MODEL `aeros-ccfrauddetect-ml-demo.fraud_detection.model_w_agg`,
    (SELECT * FROM temp2)
    )
)

SELECT *
FROM predict
)
```

Tener en cuenta de modificar nuestra cláusula “FROM” de la tabla temporal “ temp1” y que coincida con la tabla donde DataFlow inserta los datos de nuevas transacciones

## Creación de dashboards operativos para visualización de métricas en tiempo real utilizando Looker

Para consumir nuestras predicciones en nuestro dashboard, conectar Looker con la tabla “predictions_view” o la que hayas elejido para que Looker consuma las predicciones de nuestro modelo.
El codigo LookML de nuestro dashboard se detalla a continuacion y las view y explores se encuentra aqui (en GitHub) en la brach “master”

```
- dashboard: serverless_online_ml__bi
  title: Serverless Online ML & BI
  layout: newspaper
  preferred_viewer: dashboards-next
  description: ''
  refresh: 5 seconds
  elements:
  - title: Transacciones fraudulentas
    name: Transacciones fraudulentas
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: single_value
    fields: [predictions_view.count, predictions_view.predicted_is_fraud]
    filters:
      predictions_view.predicted_is_fraud: '1'
    sorts: [predictions_view.predicted_is_fraud desc]
    limit: 500
    custom_color_enabled: true
    show_single_value_title: true
    show_comparison: false
    comparison_type: value
    comparison_reverse_colors: false
    show_comparison_label: true
    enable_conditional_formatting: false
    conditional_formatting_include_totals: false
    conditional_formatting_include_nulls: false
    custom_color: "#3182c4"
    defaults_version: 1
    listen: {}
    row: 3
    col: 6
    width: 6
    height: 3
  - title: "% Transacciones fraudulentas"
    name: "% Transacciones fraudulentas"
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: single_value
    fields: [predictions_view.average_fraud]
    limit: 500
    custom_color_enabled: true
    show_single_value_title: true
    show_comparison: false
    comparison_type: value
    comparison_reverse_colors: false
    show_comparison_label: true
    enable_conditional_formatting: false
    conditional_formatting_include_totals: false
    conditional_formatting_include_nulls: false
    custom_color: "#3182c4"
    value_format: 0.00\%
    defaults_version: 1
    listen: {}
    row: 3
    col: 12
    width: 6
    height: 3
  - title: Monto total transacciones fraudulentas
    name: Monto total transacciones fraudulentas
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: single_value
    fields: [predictions_view.predicted_is_fraud, predictions_view.sum_amt]
    filters:
      predictions_view.predicted_is_fraud: '1'
    sorts: [predictions_view.predicted_is_fraud desc]
    limit: 500
    custom_color_enabled: true
    show_single_value_title: true
    show_comparison: false
    comparison_type: value
    comparison_reverse_colors: false
    show_comparison_label: true
    enable_conditional_formatting: false
    conditional_formatting_include_totals: false
    conditional_formatting_include_nulls: false
    custom_color: "#3182c4"
    value_format: "$#,##0.00"
    defaults_version: 1
    listen: {}
    row: 3
    col: 18
    width: 6
    height: 3
  - name: ''
    type: text
    title_text: ''
    subtitle_text: ''
    body_text: |-
      <div align="center" style='background-color: #3182c4; padding: 5px 10px; border: solid 1px #ededed; border-radius: 5px;'>

      <font color="#fffff" size="8" >Serverless Online ML & BI</font>

      </div>
    row: 0
    col: 0
    width: 24
    height: 3
  - title: "% Fraude por categoría"
    name: "% Fraude por categoría"
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: looker_bar
    fields: [predictions_view.category, predictions_view.count]
    filters:
      predictions_view.predicted_is_fraud: '1'
    sorts: [predictions_view.count desc]
    limit: 500
    dynamic_fields: [{args: [predictions_view.count], calculation_type: percent_of_column_sum,
        category: table_calculation, based_on: predictions_view.count, label: Percent
          of Predictions View Count, source_field: predictions_view.count, table_calculation: percent_of_predictions_view_count,
        value_format: !!null '', value_format_name: percent_0, _kind_hint: measure,
        _type_hint: number, is_disabled: true}, {args: [predictions_view.count], calculation_type: percent_of_column_sum,
        category: table_calculation, based_on: predictions_view.count, label: Percent
          of Predictions View Count, source_field: predictions_view.count, table_calculation: percent_of_predictions_view_count_2,
        value_format: !!null '', value_format_name: percent_0, _kind_hint: measure,
        _type_hint: number}]
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    y_axis_tick_density_custom: 5
    show_x_axis_label: true
    show_x_axis_ticks: true
    y_axis_scale_mode: linear
    x_axis_reversed: false
    y_axis_reversed: false
    plot_size_by_field: false
    trellis: ''
    stacking: ''
    limit_displayed_rows: false
    legend_position: center
    point_style: none
    show_value_labels: true
    label_density: 25
    x_axis_scale: auto
    y_axis_combined: true
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: "#808080"
    y_axes: [{label: '', orientation: bottom, series: [{axisId: percent_of_predictions_view_count_2,
            id: percent_of_predictions_view_count_2, name: Percent of Predictions
              View Count}], showLabels: false, showValues: false, unpinAxis: false,
        tickDensity: default, tickDensityCustom: 5, type: linear}]
    hide_legend: false
    series_types: {}
    series_colors:
      percent_of_predictions_view_count_2: "#81c785"
    defaults_version: 1
    hidden_fields: [predictions_view.count]
    listen: {}
    row: 6
    col: 0
    width: 12
    height: 7
  - title: Cantidad de fraude por fecha
    name: Cantidad de fraude por fecha
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: looker_area
    fields: [predictions_view.date, predictions_view.count]
    filters:
      predictions_view.predicted_is_fraud: '1'
    sorts: [predictions_view.date]
    limit: 500
    dynamic_fields: [{args: [predictions_view.count], calculation_type: percent_of_column_sum,
        category: table_calculation, based_on: predictions_view.count, label: Percent
          of Predictions View Count, source_field: predictions_view.count, table_calculation: percent_of_predictions_view_count,
        value_format: !!null '', value_format_name: percent_0, _kind_hint: measure,
        _type_hint: number, is_disabled: true}, {args: [predictions_view.count], calculation_type: percent_of_column_sum,
        category: table_calculation, based_on: predictions_view.count, label: Percent
          of Predictions View Count, source_field: predictions_view.count, table_calculation: percent_of_predictions_view_count_2,
        value_format: !!null '', value_format_name: percent_0, _kind_hint: measure,
        _type_hint: number, is_disabled: true}]
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    y_axis_tick_density_custom: 5
    show_x_axis_label: true
    show_x_axis_ticks: true
    y_axis_scale_mode: linear
    x_axis_reversed: false
    y_axis_reversed: false
    plot_size_by_field: false
    trellis: ''
    stacking: ''
    limit_displayed_rows: false
    legend_position: center
    point_style: circle
    show_value_labels: false
    label_density: 25
    x_axis_scale: auto
    y_axis_combined: true
    show_null_points: false
    interpolation: linear
    show_totals_labels: false
    show_silhouette: false
    totals_color: "#808080"
    color_application:
      collection_id: 7c56cc21-66e4-41c9-81ce-a60e1c3967b2
      palette_id: 5d189dfc-4f46-46f3-822b-bfb0b61777b1
      options:
        steps: 5
    y_axes: [{label: Fraudes, orientation: left, series: [{axisId: predictions_view.count,
            id: predictions_view.count, name: Predictions View}], showLabels: true,
        showValues: true, unpinAxis: false, tickDensity: default, tickDensityCustom: 5,
        type: linear}]
    x_axis_label: Fecha
    limit_displayed_rows_values:
      show_hide: hide
      first_last: first
      num_rows: 0
    hide_legend: false
    series_types: {}
    series_colors:
      predictions_view.count: "#70a8d6"
    discontinuous_nulls: false
    ordering: none
    show_null_labels: false
    defaults_version: 1
    hidden_fields:
    listen: {}
    row: 6
    col: 12
    width: 12
    height: 7
  - title: Locación de transacciones fraudulentas
    name: Locación de transacciones fraudulentas
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: looker_map
    fields: [predictions_view.location, predictions_view.count, predictions_view.city]
    filters:
      predictions_view.predicted_is_fraud: '1'
    sorts: [predictions_view.location]
    limit: 500
    map_plot_mode: points
    heatmap_gridlines: false
    heatmap_gridlines_empty: false
    heatmap_opacity: 0.5
    show_region_field: true
    draw_map_labels_above_data: true
    map_tile_provider: light
    map_position: fit_data
    map_scale_indicator: 'off'
    map_pannable: true
    map_zoomable: true
    map_marker_type: circle
    map_marker_icon_name: default
    map_marker_radius_mode: proportional_value
    map_marker_units: meters
    map_marker_proportional_scale_type: linear
    map_marker_color_mode: fixed
    show_view_names: false
    show_legend: true
    quantize_map_value_colors: false
    reverse_map_value_colors: false
    series_types: {}
    defaults_version: 1
    listen: {}
    row: 13
    col: 0
    width: 12
    height: 10
  - title: Fraudes por edad y genero
    name: Fraudes por edad y genero
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: looker_column
    fields: [predictions_view.count, predictions_view.age, predictions_view.gender]
    pivots: [predictions_view.gender]
    filters:
      predictions_view.predicted_is_fraud: '1'
    sorts: [predictions_view.gender, predictions_view.age]
    limit: 500
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    y_axis_tick_density_custom: 5
    show_x_axis_label: true
    show_x_axis_ticks: true
    y_axis_scale_mode: linear
    x_axis_reversed: false
    y_axis_reversed: false
    plot_size_by_field: false
    trellis: ''
    stacking: normal
    limit_displayed_rows: false
    legend_position: center
    point_style: none
    show_value_labels: false
    label_density: 25
    x_axis_scale: auto
    y_axis_combined: true
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: "#808080"
    y_axes: [{label: Fraudes, orientation: left, series: [{axisId: predictions_view.count,
            id: F - predictions_view.count, name: Femenino}, {axisId: predictions_view.count,
            id: M - predictions_view.count, name: Masculino}], showLabels: true, showValues: true,
        valueFormat: '', unpinAxis: false, tickDensity: default, tickDensityCustom: 5,
        type: linear}]
    x_axis_label: Edad
    series_colors:
      F - predictions_view.count: "#FF8168"
      M - predictions_view.count: "#81c785"
    series_labels:
      F - predictions_view.count: Femenino
      M - predictions_view.count: Masculino
    defaults_version: 1
    listen: {}
    row: 13
    col: 12
    width: 12
    height: 5
  - title: Top 10 fraude por profesión
    name: Top 10 fraude por profesión
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: looker_pie
    fields: [predictions_view.job, predictions_view.count]
    filters:
      predictions_view.predicted_is_fraud: '1'
    sorts: [predictions_view.count desc]
    limit: 10
    value_labels: labels
    label_type: labPer
    inner_radius: 70
    color_application: undefined
    series_colors:
      Administrator, education: "#70a8d6"
      Radio broadcast assistant: "#e50e60"
      Commissioning editor: "#81c785"
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    y_axis_tick_density_custom: 5
    show_x_axis_label: true
    show_x_axis_ticks: true
    y_axis_scale_mode: linear
    x_axis_reversed: false
    y_axis_reversed: false
    plot_size_by_field: false
    trellis: ''
    stacking: ''
    limit_displayed_rows: false
    legend_position: center
    font_size: 12
    series_types: {}
    point_style: none
    show_value_labels: false
    label_density: 25
    x_axis_scale: auto
    y_axis_combined: true
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: "#808080"
    defaults_version: 1
    leftAxisLabelVisible: false
    leftAxisLabel: ''
    rightAxisLabelVisible: false
    rightAxisLabel: ''
    smoothedBars: false
    orientation: automatic
    labelPosition: left
    percentType: total
    percentPosition: inline
    valuePosition: right
    labelColorEnabled: false
    labelColor: "#FFF"
    show_null_points: true
    interpolation: linear
    map_plot_mode: points
    heatmap_gridlines: false
    heatmap_gridlines_empty: false
    heatmap_opacity: 0.5
    show_region_field: true
    draw_map_labels_above_data: true
    map_tile_provider: light
    map_position: fit_data
    map_scale_indicator: 'off'
    map_pannable: true
    map_zoomable: true
    map_marker_type: circle
    map_marker_icon_name: default
    map_marker_radius_mode: proportional_value
    map_marker_units: meters
    map_marker_proportional_scale_type: linear
    map_marker_color_mode: fixed
    show_legend: true
    quantize_map_value_colors: false
    reverse_map_value_colors: false
    custom_color_enabled: true
    show_single_value_title: true
    show_comparison: false
    comparison_type: value
    comparison_reverse_colors: false
    show_comparison_label: true
    enable_conditional_formatting: false
    conditional_formatting_include_totals: false
    conditional_formatting_include_nulls: false
    up_color: false
    down_color: false
    total_color: false
    listen: {}
    row: 18
    col: 12
    width: 12
    height: 5
  - title: Transacciones totales
    name: Transacciones totales
    model: ccfrauddetect-ml-demo
    explore: predictions_view
    type: single_value
    fields: [predictions_view.count]
    limit: 500
    custom_color_enabled: true
    show_single_value_title: true
    show_comparison: false
    comparison_type: value
    comparison_reverse_colors: false
    show_comparison_label: true
    enable_conditional_formatting: false
    conditional_formatting_include_totals: false
    conditional_formatting_include_nulls: false
    custom_color: "#3182c4"
    defaults_version: 1
    listen: {}
    row: 3
    col: 0
    width: 6
    height: 3
```
