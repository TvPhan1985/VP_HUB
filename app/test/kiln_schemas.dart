/// Chuoi schema that cua firmware lo nung: dung lai tu cac ham build_schema_*()
/// trong Temp_Max31856-main/main/ble_ui.c voi hang so trong app_config.h
/// (cJSON_PrintUnformatted; so float in theo cJSON, vd 0.05f -> 0.05000000074505806).
/// Rieng man "calibration": TC_OFFSET_MIN_C/MAX_C/STEP_C khong co trong ban app_config.h
/// dang co, nen min/max/step o day la gia dinh (-20..20, buoc 0.1).
const List<String> kKilnSchemas = [
  '{"id":"operation","title":"Operation","fields":['
      '{"id":"pv","label":"Temperature","type":"float","unit":"°C","readonly":true},'
      '{"id":"sv","label":"Setpoint","type":"float","unit":"°C","min":0,"max":280,"step":1},'
      '{"id":"running","label":"Heating","type":"bool"}]}',
  '{"id":"pid","title":"PID","fields":['
      '{"id":"kp","label":"Kp","type":"float","min":0,"max":50,"step":0.05000000074505806},'
      '{"id":"ki","label":"Ki","type":"float","min":0,"max":5,"step":0.0005000000237487257},'
      '{"id":"kd","label":"Kd","type":"float","min":0,"max":200,"step":0.5}]}',
  '{"id":"alarm","title":"Alarm","fields":['
      '{"id":"alarm_dev","label":"Deviation alarm","type":"float","unit":"°C","min":1,"max":50,"step":1}]}',
  '{"id":"calibration","title":"Calibration","fields":['
      '{"id":"tc_offset","label":"Sensor offset","type":"float","unit":"°C","min":-20,"max":20,"step":0.10000000149011612}]}',
  '{"id":"autotune","title":"Autotune","fields":['
      '{"id":"autotune_info","label":"Status","type":"text","readonly":true},'
      '{"id":"autotune_run","label":"Run autotune","type":"bool"},'
      '{"id":"autotune_apply","label":"Apply result","type":"bool"}]}',
  '{"id":"program","title":"Program","fields":['
      '{"id":"program_enabled","label":"Multi-step program","type":"bool"},'
      '{"id":"program_step_count","label":"Number of steps","type":"float","min":1,"max":5,"step":1},'
      '{"id":"program_running","label":"Run program","type":"bool"},'
      '{"id":"program_info","label":"Status","type":"text","readonly":true}]}',
  '{"id":"program_steps","title":"Steps","fields":[],"repeat":{"count":5,"prefix":"step","fields":['
      '{"id":"t","label":"Target","type":"float","unit":"°C","min":0,"max":280,"step":1},'
      '{"id":"r","label":"Ramp time","type":"float","unit":"min","min":0,"max":999,"step":1},'
      '{"id":"s","label":"Soak time","type":"float","unit":"min","min":0,"max":999,"step":1}]}}',
];

/// VALUES mau cua tung man (dang build_values_json trong ble_ui.c)
const List<String> kKilnSampleValues = [
  '{"pv":25.4,"sv":100.0,"running":false,"sensor_ok":true,"program_running":false,"program_info":"Off","safety_latched":false,"safety_reason":""}',
  '{"kp":8.0000,"ki":0.1500,"kd":40.0000,"pv":25.4,"sv":100.0,"running":false,"sensor_ok":true,"safety_latched":false}',
  '{"alarm_dev":5.0,"pv":25.4,"sv":100.0,"running":false,"sensor_ok":true,"safety_latched":false}',
  '{"tc_offset":0.0,"pv":25.4,"sv":100.0,"running":false,"sensor_ok":true,"safety_latched":false}',
  '{"autotune_info":"Ready (relay test SSR 50%/0%)","autotune_run":false,"autotune_apply":false,"pv":25.4,"sv":100.0,"running":false,"sensor_ok":true,"safety_latched":false}',
  '{"program_enabled":false,"program_step_count":2,"program_running":false,"program_info":"Off","pv":25.4,"sv":100.0,"running":false,"sensor_ok":true,"safety_latched":false}',
  '{"step1_t":100,"step1_r":10,"step1_s":5,"step2_t":200,"step2_r":20,"step2_s":10,"step3_t":0,"step3_r":0,"step3_s":0,"step4_t":0,"step4_r":0,"step4_s":0,"step5_t":0,"step5_r":0,"step5_s":0}',
];
