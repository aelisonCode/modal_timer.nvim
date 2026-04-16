# modal_timer.nvim

A small Neovim plugin that schedules reminder popups at specific times of day (`HH:MM`).

This plugin depends on [`aelisonCode/modal_reminder.nvim`](https://github.com/aelisonCode/modal_reminder.nvim) to display the centered reminder popup.

## Features

- Schedule reminders at specific times (e.g. `08:30`, `13:30`)
- One message for all times, or one message per time
- Start / stop / status
- Runtime commands to add/remove/list timers (no need to edit plugin config)
- Persistence (JSON) so timers can survive restarting Neovim
- Optional default keymaps (can be disabled so you set your own)

## Installation (lazy.nvim)

```lua
return {
  "aelisonCode/modal_timer.nvim",
  dependencies = {
    "aelisonCode/modal_reminder.nvim",
  },
  opts = {
    autostart = true,       -- Let the plugin start when launching nvim
    times = { "09:20" },
    messages = { "Hey, time to take a break!" },
    keymaps = {
      enabled = true,
      start = "<leader>ts",
      stop = "<leader>te",
      status = "<leader>tc",
    },
  },
  config = function(_, opts)
    require("modal_timer").setup(opts)
  end,
}
```

## Configuration

### `times`

List of times in 24h format:

```lua
times = { "08:30", "13:30", "17:00" }
```

### `messages`

- If `messages` has **1** entry: it is used for all times.
- If `messages` has the **same length** as `times`: the message at index `i` is used for `times[i]`.

Examples:

```lua
messages = { "Take a break!" }
```

```lua
times = { "09:00", "13:30" }
messages = { "Morning break", "Lunch break" }
```

### `keymaps`

Default keymaps are optional:

```lua
keymaps = {
  enabled = true,
  start = "<leader>ts",
  stop = "<leader>te",
  status = "<leader>tc",
}
```

Disable default mappings if you prefer to set your own:

```lua
keymaps = { enabled = false }
```

Then define your own:

```lua
vim.keymap.set("n", "<leader>ts", require("modal_timer").start)
vim.keymap.set("n", "<leader>te", require("modal_timer").stop)
vim.keymap.set("n", "<leader>tc", require("modal_timer").status)
```

## Commands

You can manage timers at runtime (no need to edit your plugin config):

- `:AddTimer HH:MM {message...}`  
  Adds a timer at `HH:MM`. If the time already exists, it updates the message.

  Examples:
  - `:AddTimer 15:00 Time to take a break`
  - `:AddTimer 09:30 Stand up and stretch`

- `:RemoveTimer HH:MM`  
  Removes a timer by its time.
  - `:RemoveTimer 15:00`

- `:ListTimers`  
  Lists all configured timers and messages.

- `:ClearTimers`  
  Clears all configured timers and stops the scheduler.

## API

```lua
require("modal_timer").start()
require("modal_timer").stop()
require("modal_timer").status()
```

## Persistence (JSON file)

Timers added/removed via commands are saved to a JSON file so they can survive restarting Neovim.

The file is located at:

- `stdpath("data") .. "/modal_timer.json"`

Common locations:
- Linux: `~/.local/share/nvim/modal_timer.json`
- macOS: `~/.local/share/nvim/modal_timer.json`
- Windows: `%LOCALAPPDATA%\\nvim-data\\modal_timer.json`

To print the exact path on your machine:

```vim
:lua print(vim.fn.stdpath("data") .. "/modal_timer.json")
```

To reset everything, you can either run `:ClearTimers` or delete that JSON file manually.

## Scheduling behavior (today-only)

This plugin schedules reminders for the current day only:

- If a configured time has already passed today, it will be skipped (it will **not** roll over to tomorrow).
- When there are no more times remaining today, the timer stops and shows a message.

## Notes

- Times must be in `HH:MM` format.
- Reminders are scheduled using a one-shot libuv timer and re-armed after each trigger.
- Persistence stores only the configured `times` and `messages` (it does not log history), so the JSON file will not grow over time.
