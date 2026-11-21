# ZoneShift - Per-App Timezone Spoofer

[![Windhawk Mod](https://img.shields.io/badge/Windhawk-Mod-0078D7?logo=windows&logoColor=white)](https://windhawk.net/)
[![Language](https://img.shields.io/badge/Language-C%2B%2B20-blue.svg)](https://en.wikipedia.org/wiki/C%2B%2B20)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x86%20%2F%20x64)-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Spoof the timezone and local time for individual Windows applications without changing your PC clock or affecting any other running program.**

---

## Why Per-App Timezone Spoofing?

Users and developers frequently need specific applications to experience a different time or timezone without touching the Windows system clock:

- **Wallpaper Engine & Desktop Themes**:
  - Live clock wallpapers (Chromium/CEF web wallpapers, DirectX/native scene wallpapers) can show the local time of Tokyo, London, or New York, or follow day/night lighting cycles of a target hemisphere, while your actual taskbar clock remains unchanged.
- **International Outreach & Client Work**:
  - Run localized browser profiles, calendar schedulers, CRMs, Slack, or Discord matching your client's region (e.g. EST, GMT, JST) so you never miss deadlines or send messages at awkward hours.
- **Software Testing & QA**:
  - Test time-sensitive application logic across global regions (daily resets, date-boundary changes, Daylight Saving Time (DST) transitions, calendar schedulers) on demand.
- **Privacy & Anti-Tracking**:
  - Prevent browser fingerprinting scripts and analytics trackers from cross-referencing your real physical timezone against your proxy or VPN IP address.
- **Gaming & Daily Resets**:
  - Trigger region-locked in-game events, login rewards, or server reset schedules in client-based games without rebooting or desyncing system services.

---

## Technical Architecture

Windows applications query time across multiple OS layers. Simple environment variables (`TZ`) are ignored by Win32, WinRT, and Chromium. **ZoneShift** operates at the kernel, Win32, and ICU boundaries within target processes:

```
+-------------------------------------------------------------+
|    Target Application (e.g. Wallpaper Engine, Browsers)     |
+---------------------+---------------------+-----------------+
                      |                     |
                      v                     v
                 Win32 Clock           Chromium / ICU
             +-----------------+   +--------------------+
             |  GetLocalTime   |   | GetDynamicTime-    |
             | FileTimeToLocal |   | ZoneInformation    |
             +--------+--------+   +---------+----------+
                      |                      |
                      +----------+-----------+
                                 |
                                 v
                 [ ZoneShift Injected Mod Engine ]
                    (SRWLock-Protected State)
                                 |
            +--------------------+--------------------+
            |                                         |
            v                                         v
   Windows ICU (icu.dll)                    Direct Enum Registry
(Maps all IANA identifiers)             (Exact Windows Key Lookup)
```

### Core APIs Intercepted

1. **`GetDynamicTimeZoneInformation` & `GetTimeZoneInformation`**:
   - Primary modern APIs used by Chromium, Electron, CEF, Node.js, and Windows applications. Returns the spoofed timezone key, bias, and dynamic daylight status.
2. **`GetLocalTime`**:
   - Intercepts Win32 local clock requests. Converts true UTC system time to the target timezone (with DST precision) before returning it to DirectX scene wallpapers, game engines, and native UI widgets.
3. **`SystemTimeToTzSpecificLocalTime[Ex]` & `TzSpecificLocalTimeToSystemTime[Ex]`**:
   - Overrides default system conversions when applications pass `NULL` timezone structures.
4. **`FileTimeToLocalFileTime` & `LocalFileTimeToFileTime`**:
   - Converts 64-bit UTC file times into local time according to the spoofed timezone bias.
5. **`NtQuerySystemInformation` (`SystemTimeOfDayInformation`)**:
   - Replaces low-level NT kernel `TimeZoneBias` and `TimeZoneId`.
6. **Registry Spoofing (`RegQueryValueExW`)**:
   - Intercepts queries targeting `TimeZoneKeyName` and `ActiveTimeBias`.
7. **Windows ICU Dynamic Translation**:
   - Loads `ucal_getWindowsTimeZoneID` from `icu.dll` (Windows 10 1903+) to automatically map any standard IANA timezone identifier (e.g., `Europe/Warsaw`, `America/Mexico_City`, `Asia/Tokyo`) to its Windows standard equivalent.
8. **Thread-Safe State Synchronization**:
   - Mod state is protected by an `SRWLOCK` in shared/exclusive mode, eliminating race conditions during live settings updates.
9. **`WM_TIMECHANGE` Propagation**:
   - When settings are altered in Windhawk, ZoneShift posts `WM_TIMECHANGE` to the application's top-level windows so Chromium/CEF time monitors update immediately.

---

## Important Safety & Compatibility Notes

- **Default Inclusions**:
  By default, ZoneShift only targets Wallpaper Engine processes (`wallpaper32.exe`, `wallpaper64.exe`, etc.) so that other applications on your system remain unaffected out of the box.
- **Shifting UTC Time in Browsers**:
  If you enable `Shift UTC Time` (`spoofUtcTime`) and set a time shift, `GetSystemTime` will be altered. Shifting UTC time in browsers by more than a few minutes may cause HTTPS security certificate validation failures (certificates will appear not yet valid or expired), invalid TOTP two-factor authentication codes, and cookie expiration errors. Keep this option turned off unless specifically required.
- **Client Games & Anti-Cheat**:
  Many multiplayer games use anti-cheat engines (e.g. Easy Anti-Cheat, BattlEye, Vanguard) that monitor process injection and memory hooks. Use caution when adding protected game executables to the inclusion list. Note that most modern games evaluate daily reset schedules on remote servers.

---

## Adding Any Target Application

To target **any application**:
1. Open the **Windhawk UI** -> Click on **ZoneShift**.
2. Navigate to the **Details** tab -> **Advanced**.
3. Under **Process inclusion list**, add your executable name (e.g. `chrome.exe`, `slack.exe`, `yourapp.exe`).
4. Click **Save**.

---

## Mod Settings

| Setting | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| **Target Time Zone** | Dropdown | Choose from popular global presets or select `Custom`. | `Tokyo Standard Time` |
| **Custom Time Zone Key** | Text | If Custom is selected, enter any Windows Time Zone Key Name or standard IANA identifier (e.g. `Asia/Tokyo`, `Europe/Warsaw`). | `""` |
| **Custom Time Shift (Minutes)** | Number | Positive or negative minute offset added to local time (e.g. `120` adds 2 hours). Set to `0` for normal time. | `0` |
| **Shift UTC Time** | Toggle | Applies the time shift to `GetSystemTime`. Keep OFF for standard timezone spoofing. | `false` |

---

## License

MIT License. Developed by [Dev-StudioCode](https://github.com/Dev-StudioCode).
