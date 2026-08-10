# Contributing to rmux.nvim

Thanks for your interest in contributing! This project follows the conventions
of the surrounding [rmux](https://rmux.io/docs/get-started/) ecosystem.

## Ways to contribute

- **Report bugs** — open an issue with the reproduction steps, the rmux.nvim
  version, and your Neovim/rmux/terminal setup.
- **Suggest features** — open an issue describing the use case before writing
  code.
- **Fix bugs and add features** — fork the repository, make your change, and
  open a pull request.

## Prerequisites

- Neovim 0.10 or newer
- [rmux](https://rmux.io/docs/get-started/) for manual end-to-end testing
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for the test suite
- [stylua](https://github.com/JohnnyMorganz/StyLua) for formatting

## Project layout

```
lua/
  rmux/
    init.lua          Core logic: window navigation and rmux pane selection
tests/
  minimal_init.lua    Minimal Neovim config used to bootstrap the test run
  rmux_spec.lua       Plenary busted specs covering the navigation behavior
Makefile              Test runner entry point
```

## Development workflow

Clone the repository:

```sh
git clone https://github.com/tenfyzhong/rmux.nvim
cd rmux.nvim
```

Run the test suite:

```sh
make test
```

Format the Lua sources:

```sh
stylua --indent-type Spaces .
```

## Design notes

Navigation first asks Neovim to move to the adjacent window; at an editor
boundary the plugin asynchronously runs `rmux select-pane` in the same
direction. Outside an RMUX session (no `$RMUX` and `$TERM_PROGRAM != "rmux"`)
it does nothing, so the keymaps are safe in a standalone Neovim instance.

The public API is `move_to(direction)`, `move_left()`, `move_bottom()`,
`move_top()`, and `move_right()`. All behavior is covered by the specs in
`tests/rmux_spec.lua` — keep them green when changing behavior and add a spec
for any new functionality.
