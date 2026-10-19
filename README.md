# Left-Right: Tune Your Brain 🎮

A fast-paced, reaction-based mobile game built with pure Flutter. Test your reflexes by making split-second decisions against a dynamic timer, navigating through directional and color prompts, and surviving mind-bending mirror modes. 

Completely offline. Ad-free. Tracker-free. Pure gameplay.

## ✨ Features

- **Momentum Time Bank:** A dynamic 120fps countdown timer. Make correct choices quickly to add time back to the clock and build a massive "Blitz" streak. Hesitate, and the time bank drains.
- **Color & Direction Stroop Prompts:** React to challenging prompts using both directions (Left, Right, Center, Top, Bottom) and colors. Remember: *Colors override positions!*
- **Text-Flipped Mirror Modes:** A diabolical twist where spatial directions are inverted (Vertical, Horizontal, or Full Inversion). The game communicates the active rule cleanly by literally mirroring and flipping the prompt text on the screen.
- **Zen Training Mode:** A dedicated practice arena with a frozen timer. Select any unlocked wave and practice your muscle memory without the pressure of the clock.
- **Contextual Autopsy Feedback:** When you fail, the engine captures a "Death Snapshot" and provides precise, dynamic feedback explaining exactly which rule tricked your brain.
- **Wave Progression & Persistent Unlocks:** Survive escalating waves of complexity. The game automatically saves your High Score and maximum unlocked wave to local device storage.
- **Cinematic Arcade Visuals & Audio:** Features an infinite-scrolling 3D Synthwave perspective grid, zero-latency hardware-primed sound effects, and glowing, distraction-free arcade pads.
- **100% Privacy First:** No ads, no analytics, no internet permission required. Your data stays on your device.

## 🛠 Tech Stack & Architecture
- **Framework:** Pure Flutter (Dart) for native, zero-latency 60/120Hz rendering.
- **Audio Engine:** `just_audio` configured with pre-warmed hardware priming to bypass Android sleep-state audio latency.
- **Persistence:** Local device storage via `shared_preferences`.
- **Architecture:** Highly decoupled State-Driven engine with pluggable `GameModifier` rules.
- **Input:** Raw `Listener` widgets bypass the standard gesture arena for true 0ms touch-down response times.