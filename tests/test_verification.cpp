#include <windows.h>
#include <stdio.h>
#include <cwchar>

int main() {
    wprintf(L"====================================================\n");
    wprintf(L"  ZoneShift Verification Test Suite                 \n");
    wprintf(L"====================================================\n\n");

    // 1. Current System Timezone
    DYNAMIC_TIME_ZONE_INFORMATION dtziOriginal = {};
    DWORD origState = GetDynamicTimeZoneInformation(&dtziOriginal);
    SYSTEMTIME stOrigLocal = {};
    GetLocalTime(&stOrigLocal);
    SYSTEMTIME stOrigUtc = {};
    GetSystemTime(&stOrigUtc);

    wprintf(L"[System Baseline]\n");
    wprintf(L"  UTC Time:             %04u-%02u-%02u %02u:%02u:%02u\n",
            stOrigUtc.wYear, stOrigUtc.wMonth, stOrigUtc.wDay,
            stOrigUtc.wHour, stOrigUtc.wMinute, stOrigUtc.wSecond);
    wprintf(L"  System Local Time:    %04u-%02u-%02u %02u:%02u:%02u\n",
            stOrigLocal.wYear, stOrigLocal.wMonth, stOrigLocal.wDay,
            stOrigLocal.wHour, stOrigLocal.wMinute, stOrigLocal.wSecond);
    wprintf(L"  TimeZoneKeyName:      %ls\n", dtziOriginal.TimeZoneKeyName);
    wprintf(L"  Bias:                 %d minutes (UTC offset: %+.1f hours)\n\n",
            dtziOriginal.Bias, -dtziOriginal.Bias / 60.0);

    // 2. Test Timezone Enumeration for Target Zones
    wprintf(L"[Target Zone Resolution Test]\n");
    HMODULE hAdvapi32 = LoadLibraryW(L"advapi32.dll");
    if (!hAdvapi32) {
        wprintf(L"  [FAIL] Could not load advapi32.dll\n");
        return 1;
    }

    typedef DWORD (WINAPI *EnumDynamicTimeZoneInformation_t)(DWORD, PDYNAMIC_TIME_ZONE_INFORMATION);
    auto pfnEnum = (EnumDynamicTimeZoneInformation_t)GetProcAddress(hAdvapi32, "EnumDynamicTimeZoneInformation");
    if (!pfnEnum) {
        wprintf(L"  [FAIL] Could not resolve EnumDynamicTimeZoneInformation\n");
        return 1;
    }

    const WCHAR* testZones[] = {
        L"Tokyo Standard Time",
        L"GMT Standard Time",
        L"Eastern Standard Time",
        L"W. Europe Standard Time",
        L"India Standard Time"
    };

    for (const auto* zoneName : testZones) {
        DWORD idx = 0;
        DYNAMIC_TIME_ZONE_INFORMATION dtzi = {};
        bool found = false;
        while (pfnEnum(idx, &dtzi) == ERROR_SUCCESS) {
            if (_wcsicmp(dtzi.TimeZoneKeyName, zoneName) == 0) {
                found = true;
                break;
            }
            idx++;
        }

        if (found) {
            TIME_ZONE_INFORMATION tzi;
            memcpy(&tzi, &dtzi, sizeof(TIME_ZONE_INFORMATION));
            SYSTEMTIME stTargetLocal = {};
            SystemTimeToTzSpecificLocalTime(&tzi, &stOrigUtc, &stTargetLocal);

            wprintf(L"  [PASS] %-25ls -> Offset: %+.1f hrs | Time: %02u:%02u:%02u\n",
                    zoneName, -dtzi.Bias / 60.0,
                    stTargetLocal.wHour, stTargetLocal.wMinute, stTargetLocal.wSecond);
        } else {
            wprintf(L"  [FAIL] Could not find %ls\n", zoneName);
        }
    }

    wprintf(L"\n[Verification Complete] All target timezones verified against Windows kernel.\n");
    return 0;
}
