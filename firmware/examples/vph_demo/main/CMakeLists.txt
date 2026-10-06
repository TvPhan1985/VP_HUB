idf_component_register(SRCS "main.c"
                       INCLUDE_DIRS "."
                       REQUIRES vph_ble nvs_flash esp_timer)
