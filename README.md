# Arcade Trackball Smooth Scrolling

A high-precision, smoothly accelerating scrolling script for arcade trackballs like the [GRS LED Arcade Trackball Game V3 | TS-UTB-PRO](https://thunderstickstudio.com/products/grs-rgb-arcade-trackball), built with AutoHotkey v2 and AutoHotInterception.

---

## The Dream

I wanted a solution for smooth scrolling in X and Y similar to what Engineer Bro did on YouTube [here](https://www.youtube.com/watch?v=FSy9G6bNuKA). However, I didn't want to have to build a custom PCB and program a driver for it.

The project requirements were:
1. Use of Windows' high-resolution scrolling
2. Scrolling in both X and Y directions 
3. Device has momentum to it so it can spin freely after I release it

One "nice to have" was bluetooth, though I didn't end up with that.
---

## ⚙️ Requirements

- **[AutoHotkey v2](https://www.autohotkey.com/)** (AHK v1 is not compatible at the moment)
- **[AutoHotInterception](https://github.com/evilC/AutoHotInterception)**
  - AutoHotInterception requires the [Interception driver](https://github.com/oblitum/Interception/releases). Follow installation instructions carefully.

---

## 📂 Project Structure

Ensure your local folder structure matches the following:

```
ArcadeTrackballScroll/
├── ArcadeTrackballScroll.ahk
├── .env
└── Lib/
    ├── x64/
    │   ├── interception.dll
    │   └── interception.lib
    ├── x86/
    │   ├── interception.dll
    │   └── interception.lib
    └── AutoHotInterception.ahk
    └── Interception.dll
```

- `ArcadeTrackballScroll.ahk` is the main executable script.
- `.env` contains device-specific configurations.

---

## ⚡ ~~Quick~~ (Somewhat Arduous) Setup

1. **Install AutoHotkey v2**:
   - [Download from the official site](https://www.autohotkey.com/) and install.

2. **Install Interception Driver**:
   - Download the latest release from [Interception releases](https://github.com/oblitum/Interception/releases).
   - Follow the installation instructions.

   - **Restart your PC.**

3. **Setup AutoHotInterception**:
   - Download and place `AutoHotInterception.ahk` and `Interception.dll` into the `Lib` folder.

4. **Identify your Trackball Handle**:
   - Run `Monitor.ahk` from AutoHotInterception examples to identify your trackball's handle number (e.g., `11`).

5. **Configure `.env`**:
   - Copy the provided `.env.example` file to `.env`.
   - Update `.env` with your trackball handle and preferred settings:

```ini
TRACKBALL_HANDLE=11
BASE_MULTIPLIER=1
ACCELERATION_EXPONENT=1.8
SENSITIVITY=5.0
```

---

## 🚀 Usage

Double-click `ArcadeTrackballScroll.ahk` to run. Ensure the script runs with administrator privileges for full functionality.

You should get a popUp message that says "Subscribed to Trackball Movements".

---

## 🎛️ Customization

Adjust the scrolling behavior by changing parameters in the `.env` file:

| Parameter              | Description                                       | Suggested Range |
|------------------------|---------------------------------------------------|-----------------|
| `TRACKBALL_HANDLE`     | Handle ID of your trackball device.               | determined via Monitor.ahk |
| `BASE_MULTIPLIER`      | Base scroll increment for pixel-level precision.  | 1 (recommended) |
| `ACCELERATION_EXPONENT`| Controls acceleration curve (1 = linear, higher = more exponential). | 1.5–2.0 |
| `SENSITIVITY`          | Scroll speed scaling factor. Higher values accelerate faster. | 0.2–1.0 |

---

## 📜 License

This project is licensed under the **MIT License**—use freely!

