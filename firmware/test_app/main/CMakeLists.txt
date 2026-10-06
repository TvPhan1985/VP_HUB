idf_component_register(SRCS "test_main.c" "test_vph.c"
                       INCLUDE_DIRS "."
                       REQUIRES unity vph_ble
                       WHOLE_ARCHIVE)
