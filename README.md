# Audify

A macOS menu bar app that merges multiple USB microphones into one virtual input device selectable in Teams, Zoom, and any other conferencing app.

## How it works

Audify creates a hidden Core Audio **aggregate device** containing your selected microphones (with drift compensation, so their independent USB clocks stay in sync) plus the [BlackHole](https://github.com/ExistentialAudio/BlackHole) virtual driver as its output. It captures the multichannel stream, mixes it down to mono with `tanh` soft clipping, and renders the mix into BlackHole. Conferencing apps then select **"BlackHole 2ch"** as their microphone and hear all merged mics at once.

```
Mic A + Mic B ─▶ aggregate device ─▶ inputNode tap ─▶ Mixer.mixDownToMono
                                                            │
Teams/Zoom ◀─ BlackHole 2ch ◀─ outputNode ◀─ AVAudioSourceNode ◀─ RingBuffer
```

## Requirements

- macOS 13 (Ventura) or later
- [BlackHole 2ch](https://github.com/ExistentialAudio/BlackHole) virtual audio driver
- Full Xcode (only needed to run the test suite — building the app works with Command Line Tools)

## Install the BlackHole driver

```bash
brew install blackhole-2ch
```

Then log out and back in (or reboot) so `coreaudiod` loads the driver. Verify:

```bash
system_profiler SPAudioDataType | grep -i blackhole
```

## Build & run

Build and run directly during development:

```bash
swift build
swift run Audify
```

Package a proper `.app` bundle (needed for the microphone-permission prompt and to hide the app from the Dock):

```bash
./scripts/make_app.sh
open dist/Audify.app
```

The menu bar icon appears; enabling **Merge** with a device selected triggers the macOS microphone-permission prompt. After granting, the level meter moves when you speak.

## Usage

1. Click the menu bar mic icon.
2. Select the microphones you want to merge.
3. Toggle **Merge active** on.
4. In Teams/Zoom (or System Settings → Sound), choose **"BlackHole 2ch"** as your microphone.

The first selected input is the clock master; every other device gets drift compensation. Device selections and merge state persist across restarts. Hot-plugging a device re-merges it automatically if it was selected.

## Tests

```bash
swift test
```

Covers the pure logic: `Mixer`, `RingBuffer`, `LevelMeter`, `SettingsStore`, and the `AudioDevice` filter (17 tests). The Core Audio HAL paths are verified by running the app.

## Project layout

```
Sources/Audify/
├── AudifyApp.swift               # @main MenuBarExtra entry point
├── AppState.swift                  # composition root; reacts to selection + hot-plug
├── ContentView.swift               # menu bar popover UI
├── Mixer.swift                     # mono downmix + soft clip
├── RingBuffer.swift                # thread-safe capture↔render hand-off
├── LevelMeter.swift                # RMS / normalized output level
├── SettingsStore.swift             # UserDefaults persistence
├── AudioDevice.swift               # device model + selectable-input filter
├── DeviceManager.swift             # Core Audio HAL enumeration + hot-plug listener
├── AggregateDeviceController.swift # creates the hidden aggregate device
└── AudioEngine.swift               # capture → mix → render into BlackHole
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| "BlackHole driver not found" in the popover | `brew install blackhole-2ch`, then log out/in or reboot |
| No permission prompt / silent input | Run from `dist/Audify.app`, not `swift run`; check System Settings → Privacy & Security → Microphone |
| Crackling audio | Make sure the flaky device is not the first selected (the first is the clock master; all others get drift-corrected) |
| Teams doesn't list BlackHole 2ch | Restart Teams after installing the driver — apps snapshot the device list at launch |
| `swift test` fails: no such module 'XCTest' | Full Xcode required — Command Line Tools alone can't run tests |

## Roadmap

- Per-device gain sliders
- True stereo output (the `stereoOutput` flag is already wired through)
- A fully custom Core Audio Server Plug-In (no BlackHole dependency), which would allow renaming the virtual device to "Audify Input"
