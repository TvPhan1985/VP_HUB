#include <stdio.h>
#include "unity.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void app_main(void)
{
    // Cho cong USB san sang de khong mat dau log
    vTaskDelay(pdMS_TO_TICKS(1500));
    UNITY_BEGIN();
    unity_run_all_tests();
    UNITY_END();
    unsigned tests = Unity.NumberOfTests, fails = Unity.TestFailures;
    // In lai tong ket dinh ky de serial_log bat duoc du ket noi tre
    while (1) {
        printf("TEST_SUMMARY tests=%u failures=%u %s\n", tests, fails, fails ? "FAIL" : "PASS");
        vTaskDelay(pdMS_TO_TICKS(3000));
    }
}
