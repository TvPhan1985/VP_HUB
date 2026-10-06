# cJSON: IDF v5.x co san component "json"; IDF v6.x tach thanh component quan ly "espressif/cjson"
if(IDF_VERSION_MAJOR GREATER_EQUAL 6)
    set(vph_json cjson)
else()
    set(vph_json json)
endif()

idf_component_register(SRCS "vph_core.c" "vph_ble.c"
                       INCLUDE_DIRS "include"
                       REQUIRES ${vph_json}
                       PRIV_REQUIRES bt esp_hw_support esp_timer)
