# 🫁 Zenmed+ Ventilator

A Flutter-based medical ventilator monitoring and control application for Android tablets. Zenmed+ provides real-time waveform visualization, patient parameter management, and multi-mode ventilation control via USB serial communication with the ventilator hardware.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Ventilation Modes](#ventilation-modes)
- [Screens](#screens)
- [Architecture](#architecture)
- [Hardware Communication](#hardware-communication)
- [Alarm System](#alarm-system)
- [Database & Logging](#database--logging)
- [Getting Started](#getting-started)
- [Dependencies](#dependencies)
- [Configuration](#configuration)

---

## Overview

Zenmed+ is a clinical ventilator companion app designed to run on Android tablets connected to the **Zenmed 900 SE AHR Series** ventilator unit via USB serial. It handles real-time sensor data acquisition, waveform rendering, alarm management, and patient session logging — all from a landscape-locked, full-screen interface optimized for ICU use.

---

## ✨ Features

- **Real-time waveform graphs** — Airway Pressure (Paw), Volume Tidal (VT), and Flow displayed as scrolling waveforms
- **Loop graphs** — Pressure-Volume, Pressure-Flow, and Volume-Flow XY loop visualization
- **Multi-mode ventilation** — Supports 7 clinical ventilation modes
- **Patient IBW calculation** — Ideal Body Weight computed from height and gender for tidal volume recommendations
- **Alarm system** — Configurable high/low alarms for FiO₂, MVe, Pressure, VT, Humidity, Temperature, and more
- **SPO₂ & ETCO₂ monitoring** — Optional waveform display for pulse oximetry and capnography
- **Trend viewer** — Historical waveform review with pan/zoom, backed by SQLite
- **Machine log** — Timestamped audit trail of all parameter changes, alarms, and events
- **Pre-use calibration checklist** — Step-by-step sensor validation before ventilation begins
- **Inspiration Hold** — Manually hold inspiratory phase for clinical assessment
- **Battery status indicator** — Real-time AC/battery status display
- **Wakelock** — Screen stays on throughout patient monitoring

---

## 🫀 Ventilation Modes

| Code | Full Name |
|------|-----------|
| `V-CMV` | Volume Controlled Mandatory Ventilation |
| `SIMV` | Synchronized Intermittent Mandatory Ventilation |
| `(S)V-CMV` | Sensing Volume Controlled Mandatory Ventilation |
| `PSV` | Pressure Support Ventilation |
| `P-CMV` | Pressure Controlled Mandatory Ventilation |
| `P-SIMV` | Pressure Controlled SIMV |
| `CPAP` | Continuous Positive Airway Pressure |

Each mode configures visible controls (flow, pressure, volume, IE ratio, RR) and drives the appropriate ventilation cycle logic.

---

## 📱 Screens

### 1. `PatientDetailsPage`
Entry screen for entering patient demographics before connecting.

- Patient name, height, birth date, gender
- Ventilator option selection (Adult / Pediatric)
- Ventilation mode selection
- Saves all settings to `SharedPreferences`
- Navigates to `MonitorPage` on connect

### 2. `VentSelectionPage`
Tab-based alternative setup screen combining patient details and mode selection in a tabbed layout.

### 3. `MonitorPage`
Main clinical monitoring screen. Landscape-locked, full-screen.

**Layout sections:**
- **Top bar** — Status row: patient info, mode, option, Insp Hold, duration, battery, start/pause, power off
- **Main area** (left) — Real-time waveform graphs (Paw / VT / Flow) or SPO₂ / ETCO₂ graphs; plus trend viewer and machine log
- **Main area** (right) — Lung animation / loop graphs / SPO₂ & ETCO₂ values; cycle timing info
- **Side info panel** — Detailed numeric readouts: PPeak, VTe, VTi, MVe, PEEP, Flow Insp/Exp, I/E Ratio, Auto PEEP, VT/IBW
- **Bottom bar** — Parameter setting buttons (FiO₂, VTidal, PEEP, Pressure, Flow, Over Pressure, I/E Ratio, RR, trigger)
- **Alarm strip** — Color-coded alarm indicators at the bottom

---

## 🏗️ Architecture

```
lib/
├── main.dart                  # App entry point & routing
├── ventilator.dart            # Core business logic & USB comms
├── constants.dart             # App-wide constants
├── dtmodel.dart               # Data models (GraphXYData, etc.)
└── screen/
│   ├── monitor.dart           # Main monitoring screen
│   ├── patientdetails.dart    # Patient setup screen
│   └── ventselection.dart     # Mode/patient selection screen
└── component/
    ├── grafikwithpointer.dart  # Real-time scrolling waveform widget
    ├── graphdbwithpointer.dart # Historical waveform with pointer
    ├── simplegraph.dart        # XY loop graph widget
    ├── database_helper.dart    # SQLite helper
    ├── info.dart               # Static info/page state
    ├── infobox.dart            # Numeric value display card
    ├── alarmbox.dart           # Alarm indicator widget
    ├── reusablecard.dart       # Generic tappable card
    ├── settingbutton.dart      # Parameter control button
    ├── confirmdialog.dart      # Yes/No confirmation dialog
    ├── valuepickerdialog.dart  # Numeric value picker dialog
    ├── rangevaluepickerdialog.dart # Min/Max alarm range picker
    ├── informationdialogbox.dart   # Information display dialog
    └── logcard.dart            # Machine log list item
```

### Core Class: `Ventilator`

The `Ventilator` class is the heart of the application. It encapsulates:

- USB serial port management (`usb_serial`)
- All ventilation cycle logic per mode (`_cmvMode`, `_cpapMode`, `_psvMode`, `_newSimvMode`)
- Sensor data parsing and dataset management
- Parameter getters/setters that write directly to hardware
- IBW and tidal volume calculations
- Database operations (waveform trend storage, duration logging)
- Alarm threshold management

---

## 🔌 Hardware Communication

Communication is over **USB serial** at **115200 baud**, 8N1, using the `usb_serial` package with `Transaction.stringTerminated` (CRLF-delimited).

### Incoming data packets

| Prefix | Content |
|--------|---------|
| `t.` | Flow, pressure, trigger values, volume (12 fields) |
| `a.` | Battery, UV/O2/Air flags, FiO2, temperature, humidity |
| `v.` | SPO₂ value |
| `l.` | ETCO₂ value |
| `w` | Machine initialized |
| `x` | Flow sensor calibration OK |
| `y` | Pressure sensor calibration OK |
| `z` | Air leak test OK |
| `m` | O₂ sensor OK |

### Outgoing commands

| Command | Action |
|---------|--------|
| `1.\n` | Start inspiration |
| `2.\n` | End inspiration |
| `3.\n` | Heartbeat / keep-alive |
| `4.\n` | CPAP / expiration mode |
| `5.\n` | Pause exhale |
| `B.\n` | Trigger leak alert |
| `C.\n` / `D.\n` | PEEP valve open/close |
| `v.<n>` | Set tidal volume |
| `f.<n>` | Set flow (×100) |
| `p.<n>` | Set pressure |
| `pe.<n>` | Set PEEP |
| `fi.<n>` | Set FiO₂ |
| `op.<n>` | Set over-pressure limit |
| `rr.<n>` | Set respiratory rate |
| `i.<n>` / `e.<n>` | Set I/E ratio components |
| `mode.<n>` | Set ventilation mode code |
| `W.\n` | Apply all parameters |
| `X.\n` / `Y.\n` / `Z.\n` / `M.\n` | Trigger sensor checks |
| `A.\n` / `V.\n` | Request status update |

---

## 🚨 Alarm System

Alarms are evaluated every ~1 second during active ventilation. Each alarm has configurable **min** and **max** thresholds adjustable from the UI.

| Alarm | Parameter |
|-------|-----------|
| FiO₂ | Inspired oxygen fraction |
| MVe | Minute ventilation |
| P | Peak airway pressure |
| VT | Tidal volume |
| HU | Humidity |
| T | Temperature |
| O₂ | O₂ supply pressure |
| Air | Air supply pressure |
| UV | UV sterilization status |
| AC | AC power |
| BAT | Battery level (low) |

Active alarms cause the header bar to **blink red** and trigger an audible beep. Double-tapping the alarm bar silences audio without clearing the visual alarm.

---

## 🗄️ Database & Logging

SQLite (via `sqflite`) is used for two purposes:

### Waveform trend storage
- Stores Paw, VT, and Flow samples continuously during ventilation
- Maximum retained: **1,296,000 samples** (~15 days at 1 Hz)
- Oldest data auto-purged when limit is exceeded
- Viewable in the **Trend** viewer with pan navigation

### Event log
- All parameter changes, calibration steps, alarm events, and session start/stop are timestamped and stored
- Viewable in the **Log** panel with pagination (50 entries per page)
- Total machine usage time is accumulated and displayed

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 2.x
- Android device/tablet with USB OTG support
- USB serial adapter connecting to ventilator hardware

### Installation

```bash
git clone https://github.com/your-org/zenmed-ventilator.git
cd zenmed-ventilator
flutter pub get
flutter run
```

> ⚠️ This application is designed for **Android only** and must be run in **landscape orientation** on a tablet.

### First Use

1. Launch the app — you will be taken to the **Patient Details** screen.
2. Enter patient name, height, birth date, and gender.
3. Select ventilator option (Adult / Pediatric) and ventilation mode.
4. Tap **Connect To Machine**.
5. On the **Monitor** screen, complete the **Initial Calibration** checklist:
   - Air Leakage test
   - Flow sensor calibration
   - Pressure sensor calibration
   - O₂ sensor check
   - Machine initialization
6. Once all checks pass, press ▶ to **Start Ventilation**.

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `usb_serial` | USB serial communication with ventilator hardware |
| `sqflite` | SQLite database for trend and log storage |
| `shared_preferences` | Persist patient/session settings |
| `uuid` | Unique IDs for database records |
| `soundpool` | Audio asset management |
| `flutter_beep` | System beep for alarms |
| `assets_audio_player` | Audio playback |
| `font_awesome_flutter` | Icon set for UI |
| `wakelock` | Prevent screen timeout during monitoring |

---

## ⚙️ Configuration

Key constants are defined in `constants.dart`:

| Constant | Description |
|----------|-------------|
| `kPrimaryColor` | Main background color |
| `kAccentColor` | Accent / alarm highlight color |
| `kSecondaryColor` | Card and button color |
| `kDataWidth` | Number of samples in real-time waveform buffer |
| `kLineSegment` | Number of Y-axis grid segments |
| `kVtIBW` | ml/kg IBW ratio for tidal volume recommendation |
| `kVentSeries` | Device series name (display only) |
| `kSerialNumber` | Device serial number (display only) |
| `kMinHeight` / `kMaxHeight` | Patient height picker bounds |

---

## ⚠️ Disclaimer

This software is intended for use **by trained medical professionals only**. It must not be used as the sole means of patient monitoring. Always follow your institution's clinical protocols and verify all parameter settings before initiating ventilation.

---

## 📄 License

This project is proprietary. All rights reserved © Zenmed Medical.
