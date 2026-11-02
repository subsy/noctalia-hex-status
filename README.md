# Hex Status for Noctalia

A bar widget for [Noctalia](https://noctalia.dev) that shows what the
[Hex](https://github.com/anomalyco/hex) dictation app is doing: ready, recording,
recording a meeting, transcribing, preparing its speech model, listener off, or not running.

| State | Glyph |
|---|---|
| Ready | `microphone` |
| Recording | `microphone-filled`, error colour |
| Meeting | `users`, error colour |
| Transcribing | `loader`, primary colour |
| Preparing model | `download` |
| Listener off / needs attention / not running | `microphone-off` |

The tooltip adds the model name and notes when a Hex update is available.

- **Left click:** toggle dictation via `hex-toggle` (types into Moonlight instead of pasting)
- **Middle click:** cancel the dictation
- **Right click:** open the Hex window

## How it works

Hex has no status stream, so one shared poller service (not each bar instance) polls `hex status --json` (a few milliseconds over
Hex's local socket) every `poll_ms`, default 300, and redraws only when the state or tooltip
changes. Exit code 3 from `hex` means Hex isn't running.

## Install

```sh
git clone https://github.com/subsy/noctalia-hex-status \
  "${XDG_DATA_HOME:-$HOME/.local/share}/noctalia/plugins/hex-status"
noctalia msg plugins enable subsy/hex-status
```

Then add a bar widget of type `subsy/hex-status:status`.

## Settings

- `show_label` (default off): show a word such as "Recording" next to the icon when not idle.
- `poll_ms` (plugin setting; default 300, 100 to 5000): how often to ask Hex for its status.
