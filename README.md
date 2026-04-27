# All Clear

**All Clear** is a small native weather app for **iOS** and **macOS** built with SwiftUI. It uses Apple’s **WeatherKit** and **Core Location** to show conditions and a **precipitation-focused** outlook for where you are.

## What it does

- Fetches the current location and loads a short-range forecast: **today** and **tomorrow**, with **hourly** data for the next two days.
- Puts **rain and other precipitation** in the foreground with an hourly view so you can see when the weather is “all clear” in practice.
- Lets you **limit the clock hours** you care about—e.g. commute or school windows—via an hour picker, and switch between that **selected-hours** view and **all 24 hours**. The choice is remembered between launches (shared on iOS/macOS via the same `UserDefaults` key where it applies).
