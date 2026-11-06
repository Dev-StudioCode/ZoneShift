# 🌐 ZoneShift - Per-App Timezone Spoofer

[![Windhawk Mod](https://img.shields.io/badge/Windhawk-Mod-0078D7?logo=windows&logoColor=white)](https://windhawk.net/)
[![Language](https://img.shields.io/badge/Language-C%2B%2B20-blue.svg)](https://en.wikipedia.org/wiki/C%2B%2B20)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x86%20%2F%20x64)-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

> **Spoof the timezone and local time for individual Windows applications without changing your PC clock or affecting any other running program.**

---

## 📌 Why Per-App Timezone Spoofing?

Users and developers frequently need specific applications to experience a different time or timezone without touching the Windows system clock:

- 🎨 **Wallpaper Engine & Desktop Themes**:
  - Live clock wallpapers (Chromium/CEF web wallpapers, DirectX/native scene wallpapers) can show the local time of Tokyo, London, or New York, or follow day/night lighting cycles of a target hemisphere, while your actual taskbar clock remains unchanged.
- 🌍 **International Outreach & Client Work**:
  - Run localized browser profiles, calendar schedulers, CRMs, Slack, or Discord matching your client's region (e.g. EST, GMT, JST) so you never miss deadlines or send messages at awkward hours.
- 🧪 **Software Testing & QA**:
  - Test time-sensitive application logic across global regions (daily resets, date-boundary changes, Daylight Saving Time (DST) transitions, calendar schedulers) on demand.
- 🛡️ **Privacy & Anti-Tracking**:
  - Prevent browser fingerprinting scripts and analytics trackers from cross-referencing your real physical timezone against your proxy or VPN IP address.
- 🎮 **Gaming & Daily Resets**:
  - Trigger region-locked in-game events, login rewards, or server reset schedules in client-based games without rebooting or desyncing system services.

---

## ⚙️ How It Works (Technical Architecture)

Windows applications query time across multiple OS layers. Simple environment variables (`TZ`) are ignored by Win32, WinRT, and Chromium. **ZoneShift** operates at the kernel/user32/ICU boundary within target processes:

```
┌────────────────────────────────────────────────────────┐
│ Target Application (e.g., Wallpaper Engine, Chrome)   │
└───────┬────────────────────────┬────────────────┬──────┘
        │                        │                │
        ▼                        ▼                ▼
   Win32 Clock              Chromium / ICU       Legacy / Low-Level
 ┌─────────────────┐      ┌─────────────────┐   ┌──────────────────┐
 │  GetLocalTime   │      │GetDynamicTime   │   │NtQuerySystemInfo │
 │FileTimeToLocal..│      │ZoneInformation  │   │RegQueryValueExW  │
 └────────┬────────┘      └────────┬────────┘   └────────┬─────────┘
          │                        │                     │
          └───────────────┬────────┴─────────────────────┘
                          │
                          ▼
             ┌─────────────────────────┐
             │    ZoneShift Engine     │  <-- Intercepts & spoofs in-memory
             └────────────┬────────────┘
                          ▼
            Dynamic Timezone Calculations
            (Daylight Saving, Offsets, IANA)
```

### Intercepted Windows APIs:
1. **`GetDynamicTimeZoneInformation` & `GetTimeZoneInformation`**:
   - Intercepts modern timezone queries used by Chromium, Electron, CEF (Wallpaper Engine web wallpapers), Node.js, and ICU. Informs apps of the spoofed timezone key and daylight status.
2. **`GetLocalTime`**:
   - Intercepts Win32 local clock requests. Converts true UTC system time to the target timezone (with DST precision) before returning it to DirectX scene wallpapers, game engines, and native UI widgets.
3. **`SystemTimeToTzSpecificLocalTime[Ex]` & `TzSpecificLocalTimeToSystemTime[Ex]`**:
   - Overrides default system conversions when applications pass `NULL` timezone structures.
4. **`FileTimeToLocalFileTime` & `LocalFileTimeToFileTime`**:
   - Converts 64-bit UTC file times into local time according to the spoofed timezone bias.
5. **`NtQuerySystemInformation` (`SystemTimeOfDayInformation`)**:
   - Replaces the low-level NT kernel `TimeZoneBias` and `TimeZoneId` for deep native profiling.
6. **Registry Spoofing (`RegQueryValueExW`)**:
   - Intercepts registry queries targeting `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` (`TimeZoneKeyName`, `ActiveTimeBias`).
7. **Dynamic `WM_SETTINGCHANGE` Propagation**:
   - When settings are altered in Windhawk, ZoneShift notifies top-level windows so Chromium/CEF and UI caches refresh immediately without restarting the app.

---

## 🚀 Quick Start & Installation

ZoneShift is developed as a native [Windhawk](https://windhawk.net/) mod.

### Option A: Automatic 1-Click Install (Recommended)
Run PowerShell as Administrator in the repository folder:
```powershell
.\install-to-windhawk.ps1 -AutoCompile
```
This automatically copies `zoneshift.wh.cpp` into your Windhawk local mods directory, compiles both 64-bit and 32-bit binaries, and registers the mod.

### Option B: Manual Setup via Windhawk UI
1. Open the **Windhawk** application.
2. Go to **Developer Channel** (or click the three dots `...` -> **Create Local Mod**).
3. Paste the contents of [`zoneshift.wh.cpp`](file:///D:/%23Anti%20Gravity/Windhalk/ZoneShift/zoneshift.wh.cpp) into the editor.
4. Click **Compile Mod**.
5. Once compiled, toggle the mod to **ENABLED**.

---

## 🎛️ Mod Settings & Customization

Inside Windhawk (`ZoneShift -> Settings`), you can customize:

| Setting | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| **Target Time Zone** | Dropdown | Choose from popular global presets or select `Custom`. | `Tokyo Standard Time (UTC+09:00)` |
| **Custom Time Zone Key** | Text | Enter any of Windows' 144 Time Zone keys (e.g. `Alaskan Standard Time`) or an IANA ID (`Asia/Tokyo`, `Europe/London`). | `""` |
| **Time Shift (Minutes)** | Number | Positive or negative minute offset added to local time (e.g. `120` for +2 hours). Perfect for testing daily resets. | `0` |
| **Shift UTC Time** | Toggle | Also applies time shifts to `GetSystemTime`. Keep OFF unless testing apps that strictly query UTC. | `false` |
| **Debug Logging** | Toggle | Outputs verbose hook messages to the Windhawk Mod Manager log console. | `false` |

### Popular Presets:
- 🇯🇵 Tokyo, Japan (`UTC+09:00`)
- 🇬🇧 London, UK (`GMT / BST, UTC+00:00 / UTC+01:00`)
- 🌐 UTC (`Coordinated Universal Time, UTC+00:00`)
- 🇪🇺 Berlin / Paris / Rome / Amsterdam (`CET / CEST, UTC+01:00 / UTC+02:00`)
- 🇺🇸 New York / Toronto (`US Eastern, UTC-05:00 / UTC-04:00`)
- 🇺🇸 Chicago / Dallas (`US Central, UTC-06:00 / UTC-05:00`)
- 🇺🇸 Denver (`US Mountain, UTC-07:00 / UTC-06:00`)
- 🇺🇸 Los Angeles / Seattle (`US Pacific, UTC-08:00 / UTC-07:00`)
- 🇮🇳 New Delhi / Mumbai (`IST, UTC+05:30`)
- 🇨🇳 Beijing / Shanghai / Hong Kong (`UTC+08:00`)
- 🇦🇺 Sydney / Melbourne (`AEST / AEDT, UTC+10:00 / UTC+11:00`)

---

## 🎯 Adding Any Target Application

ZoneShift includes pre-configured injection rules for:
- **Wallpaper Engine**: `wallpaper32.exe`, `wallpaper64.exe`, `webwallpaper32.exe`, `webwallpaper64.exe`, `edgewallpaper32.exe`, `edgewallpaper64.exe`, `ui32.exe`, `wallpaperui.exe`
- **Browsers**: `chrome.exe`, `msedge.exe`, `brave.exe`, `firefox.exe`
- **Messaging**: `Discord.exe`, `Slack.exe`, `Telegram.exe`

To target **any custom application**:
1. Open **Windhawk** -> Click on **ZoneShift**.
2. Navigate to the **Details** tab -> **Advanced**.
3. Under **Process inclusion list**, add your executable (e.g., `yourapp.exe`, `game.exe`).
4. Click **Save**. The app will automatically run with the spoofed timezone on next launch!

---

## 🧪 Build & Verification Test Suite

You can compile and test ZoneShift locally using the included test suite:
```powershell
powershell -ExecutionPolicy Bypass -File .\build-and-test.ps1
```
This builds both 32-bit and 64-bit binaries and executes the kernel verification harness (`tests/test_verification.cpp`).

---

## 📄 License

MIT License. Designed and developed by [Dev-StudioCode](https://github.com/Dev-StudioCode).
