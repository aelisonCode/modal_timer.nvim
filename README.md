# modal_timer.nvim

A small Neovim plugin that schedules reminder popups at specific times of day (HH:MM).

This plugin depends on [`aelisonCode/modal_reminder.nvim`](https://github.com/aelisonCode/modal_reminder.nvim) to display the centered reminder popup.

## Features

- Schedule reminders at specific daily times (e.g. `08:30`, `13:30`)
- One message for all times, or one message per time
- Start / stop / status
- Optional default keymaps (can be disabled so you set your own)

## Installation (lazy.nvim)

```lua
{
  "aelisonCode/modal_timer.nvim",
  dependencies = {
    "aelisonCode/modal_reminder.nvim",
  },
  opts = {
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

## API

```lua
require("modal_timer").start()
require("modal_timer").stop()
require("modal_timer").status()
```

## Notes

- Times must be in `HH:MM` format.
- Reminders are scheduled using a one-shot libuv timer and re-armed after each trigger.
