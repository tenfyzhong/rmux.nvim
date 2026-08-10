# rmux.nvim

Seamless directional navigation between Neovim windows and
[RMUX](https://rmux.io) panes.

`rmux.nvim` first asks Neovim to move to the adjacent window. At an editor
boundary it asynchronously runs `rmux select-pane` in the same direction. It
does nothing outside an RMUX session, so the mappings are safe in a standalone
Neovim instance.

## Requirements

- Neovim 0.10 or newer
- `rmux` with the `select-pane` command available on `PATH`

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "tenfyzhong/rmux.nvim",
  config = function()
    require("rmux").setup({})
  end,
  keys = {
    {
      "<C-h>",
      function()
        require("rmux").move_left()
      end,
      mode = { "n", "t" },
      desc = "rmux: go to left window",
    },
    {
      "<C-j>",
      function()
        require("rmux").move_bottom()
      end,
      mode = { "n", "t" },
      desc = "rmux: go to window below",
    },
    {
      "<C-k>",
      function()
        require("rmux").move_top()
      end,
      mode = { "n", "t" },
      desc = "rmux: go to window above",
    },
    {
      "<C-l>",
      function()
        require("rmux").move_right()
      end,
      mode = { "n", "t" },
      desc = "rmux: go to right window",
    },
  },
}
```

RMUX must pass these keys into Neovim and select a pane for other processes.
The following `rmux.conf` bindings already provide that behavior:

<!-- markdownlint-disable MD013 -->

```tmux
bind -n C-h if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?g?(view|n?vim?x?)(diff)?$'" "send-keys C-h" "select-pane -L"
bind -n C-j if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?(g?(view|n?vim?x?)(diff)?|fzf)$'" "send-keys C-j" "select-pane -D"
bind -n C-k if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?(g?(view|n?vim?x?)(diff)?|fzf)$'" "send-keys C-k" "select-pane -U"
bind -n C-l if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?g?(view|n?vim?x?)(diff)?$'" "send-keys C-l" "select-pane -R"
```

<!-- markdownlint-enable MD013 -->

## Configuration

The defaults automatically detect RMUX through `$RMUX` or
`$TERM_PROGRAM == "rmux"`:

```lua
require("rmux").setup({
  executable = "rmux",
  enabled = nil,
})
```

Set `enabled` to `true` to force RMUX integration or `false` to disable it.
The public navigation API is `move_to(direction)`, `move_left()`,
`move_bottom()`, `move_top()`, and `move_right()`.

## Tests

The test suite uses plenary.nvim from the local Neovim data directory:

```sh
make test
```
