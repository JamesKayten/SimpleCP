# Flyout Delay Settings UI - Visual Guide

## Settings Window Location

```
┌─────────────────────────────────────────────────────────┐
│  [General] [Appearance] [Clips] [Snippets]             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Appearance Settings                                    │
│  ─────────────────────────────────────────────────     │
│                                                         │
│  Theme                                                  │
│  [ Auto | Light | Dark ]                               │
│                                                         │
│  ─────────────────────────────────────────────────     │
│                                                         │
│  Window Opacity                                         │
│  [━━━━━━━━━━━━━━━━━━━━━] 95%                           │
│                                                         │
│  ─────────────────────────────────────────────────     │
│                                                         │
│  Fonts                                                  │
│  Interface: [SF Pro    ] [- 13 +] 13pt                 │
│  Clips:     [SF Mono   ] [- 12 +] 12pt                 │
│                                                         │
│  ─────────────────────────────────────────────────     │
│                                                         │
│  Flyout & Preview Delays                              │
│  ☑ Show snippet previews on hover                     │
│                                                         │
│    Clip preview delay:                                 │
│    [━━━━━━━━━━━━━━━━━━━━━] 0.7s                        │
│                                                         │
│  Clip group flyout delay:                             │
│  [━━━━━━━━━━━━━━━━━━━━━] 0.5s                          │
│                                                         │
│  Folder flyout delay:                                  │
│  [━━━━━━━━━━━━━━━━━━━━━] 1.0s                          │
│                                                         │
│  Adjust how long to hover before flyouts appear        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Example Scenarios

### Scenario 1: Fast User (Power User)
**Goal**: Quick access with minimal delay

```
Settings:
  Clip preview delay:        0.2s  [fast response]
  Clip group flyout delay:   0.1s  [instant access]
  Folder flyout delay:       0.3s  [quick folder view]
```

**Behavior**: Flyouts appear almost instantly on hover, allowing rapid navigation through clips and folders.

### Scenario 2: Default User (Standard)
**Goal**: Balanced experience

```
Settings:
  Clip preview delay:        0.7s  [standard tooltip timing]
  Clip group flyout delay:   0.5s  [moderate delay]
  Folder flyout delay:       1.0s  [deliberate folder view]
```

**Behavior**: Comfortable delays that avoid accidental triggers while providing responsive feedback.

### Scenario 3: Careful User (Accessibility)
**Goal**: Avoid accidental triggers, more control time

```
Settings:
  Clip preview delay:        1.5s  [longer confirmation time]
  Clip group flyout delay:   1.2s  [reduced accidents]
  Folder flyout delay:       2.0s  [maximum control]
```

**Behavior**: Longer delays give users more time to position cursor deliberately, ideal for users with motor control challenges.

## Interactive Elements

### Slider Control Details

Each slider provides:
- **Range**: 0.1s to 2.0s
- **Step**: 0.1s increments
- **Visual feedback**: Real-time display of current value
- **Format**: Shows as "0.5s", "1.2s", etc.

Example slider states:
```
Minimum (0.1s):  [●─────────────] 0.1s  
Default (0.7s):  [────────●─────] 0.7s  
Maximum (2.0s):  [─────────────●] 2.0s  
```

### Conditional Display

The clip preview delay only appears when "Show snippet previews" is enabled:

```
When DISABLED:
  ☐ Show snippet previews on hover
  
  Clip group flyout delay: [slider]
  Folder flyout delay:     [slider]

When ENABLED:
  ☑ Show snippet previews on hover
  
    Clip preview delay:      [slider]  ← Only shown when enabled
  
  Clip group flyout delay: [slider]
  Folder flyout delay:     [slider]
```

## Visual Feedback in Main Window

### Before (Hovering)
```
User hovers over folder...
  ↓
[Waiting... 0.5s elapsed]
  ↓
[Waiting... 1.0s elapsed] ← Delay reached!
  ↓
Flyout appears →
```

### After (With Different Delay)
```
User changes setting to 0.3s...
  ↓
User hovers over folder...
  ↓
[Waiting... 0.3s elapsed] ← Delay reached!
  ↓
Flyout appears → [Much faster!]
```

## Reset to Defaults

The "Reset to Defaults" button at the bottom of the settings window will restore:

```
┌─────────────────────────────────────────────┐
│                                             │
│  [All settings restored]                    │
│                                             │
│  • Clip preview delay:       0.7s           │
│  • Clip group flyout delay:  0.5s           │
│  • Folder flyout delay:      1.0s           │
│                                             │
└─────────────────────────────────────────────┘
```

## Implementation Notes

### Real-time Updates
- Changes apply **immediately** - no restart required
- Test by adjusting slider, then hovering over an item
- You'll feel the difference in delay right away

### Persistence
- Settings are stored in UserDefaults
- Values persist across app launches
- Shared across all windows (if multi-window support added)

### Edge Cases Handled
- Values default to standard delays if not set
- Slider prevents invalid values (clamped to 0.1s - 2.0s)
- Type-safe with Swift's `TimeInterval` type

---

**UI Framework**: SwiftUI
**Platform**: macOS
**Min Range**: 0.1 seconds
**Max Range**: 2.0 seconds
**Step Size**: 0.1 seconds
