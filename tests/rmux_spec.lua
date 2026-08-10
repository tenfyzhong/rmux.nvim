describe("rmux navigation", function()
  local current_window
  local executable
  local notifications
  local originals
  local rmux_commands
  local window_moves

  before_each(function()
    current_window = 1
    executable = 1
    notifications = {}
    rmux_commands = {}
    window_moves = {}

    originals = {
      executable = vim.fn.executable,
      get_current_win = vim.api.nvim_get_current_win,
      notify = vim.notify,
      rmux = vim.env.RMUX,
      schedule = vim.schedule,
      system = vim.system,
      term_program = vim.env.TERM_PROGRAM,
      wincmd = vim.cmd.wincmd,
    }

    vim.env.RMUX = "/tmp/rmux/default,123,0"
    vim.env.TERM_PROGRAM = "rmux"
    vim.api.nvim_get_current_win = function()
      return current_window
    end
    vim.cmd.wincmd = function(key)
      table.insert(window_moves, key)
    end
    vim.fn.executable = function()
      return executable
    end
    vim.notify = function(message, level)
      table.insert(notifications, { message = message, level = level })
    end
    vim.schedule = function(callback)
      callback()
    end
    vim.system = function(command, _, callback)
      table.insert(rmux_commands, command)
      callback({ code = 0, stderr = "" })
    end

    package.loaded.rmux = nil
    package.loaded["rmux.config"] = nil
  end)

  after_each(function()
    vim.env.RMUX = originals.rmux
    vim.env.TERM_PROGRAM = originals.term_program
    vim.api.nvim_get_current_win = originals.get_current_win
    vim.cmd.wincmd = originals.wincmd
    vim.fn.executable = originals.executable
    vim.notify = originals.notify
    vim.schedule = originals.schedule
    vim.system = originals.system
  end)

  it("moves inside Neovim before using rmux", function()
    vim.cmd.wincmd = function(key)
      table.insert(window_moves, key)
      current_window = 2
    end

    local rmux = require("rmux")
    local moved, destination = rmux.move_left()

    assert.is_true(moved)
    assert.are.equal("nvim", destination)
    assert.are.same({ "h" }, window_moves)
    assert.are.same({}, rmux_commands)
  end)

  it("moves to an rmux pane at a Neovim boundary", function()
    local rmux = require("rmux")
    local moved, destination = rmux.move_bottom()

    assert.is_true(moved)
    assert.are.equal("rmux", destination)
    assert.are.same({ "j" }, window_moves)
    assert.are.same({
      { "rmux", "select-pane", "-D" },
    }, rmux_commands)
  end)

  it("maps all public directions", function()
    local rmux = require("rmux")

    rmux.move_left()
    rmux.move_bottom()
    rmux.move_top()
    rmux.move_right()

    assert.are.same({ "h", "j", "k", "l" }, window_moves)
    assert.are.same({
      { "rmux", "select-pane", "-L" },
      { "rmux", "select-pane", "-D" },
      { "rmux", "select-pane", "-U" },
      { "rmux", "select-pane", "-R" },
    }, rmux_commands)
  end)

  it("does not start rmux outside an rmux session", function()
    vim.env.RMUX = nil
    vim.env.TERM_PROGRAM = "ghostty"

    local rmux = require("rmux")
    local moved, destination = rmux.move_right()

    assert.is_false(moved)
    assert.are.equal("boundary", destination)
    assert.are.same({}, rmux_commands)
  end)

  it("reports a missing rmux executable", function()
    executable = 0

    local rmux = require("rmux")
    local moved, destination = rmux.move_top()

    assert.is_false(moved)
    assert.are.equal("error", destination)
    assert.are.equal(1, #notifications)
    assert.matches("rmux executable", notifications[1].message)
    assert.are.equal(vim.log.levels.ERROR, notifications[1].level)
  end)

  it("reports an rmux command failure without stderr", function()
    vim.system = function(command, _, callback)
      table.insert(rmux_commands, command)
      callback({ code = 1 })
    end

    local rmux = require("rmux")
    rmux.move_left()

    assert.are.equal(1, #notifications)
    assert.matches("failed to select pane: exit code 1", notifications[1].message)
  end)

  it("can be explicitly disabled", function()
    local rmux = require("rmux")
    rmux.setup({ enabled = false })
    local moved, destination = rmux.move_top()

    assert.is_false(moved)
    assert.are.equal("boundary", destination)
    assert.are.same({}, rmux_commands)
  end)

  it("accepts a custom executable and forced detection", function()
    vim.env.RMUX = nil
    vim.env.TERM_PROGRAM = "ghostty"

    local rmux = require("rmux")
    rmux.setup({
      executable = "/opt/rmux/bin/rmux",
      enabled = true,
    })
    rmux.move_to("right")

    assert.are.same({
      { "/opt/rmux/bin/rmux", "select-pane", "-R" },
    }, rmux_commands)
  end)

  it("rejects unknown directions", function()
    local rmux = require("rmux")

    assert.has_error(function()
      rmux.move_to("diagonal")
    end, "rmux.nvim: invalid direction: diagonal")
  end)
end)
