local M = {}

local directions = {
  bottom = { nvim = "j", rmux = "-D" },
  left = { nvim = "h", rmux = "-L" },
  right = { nvim = "l", rmux = "-R" },
  top = { nvim = "k", rmux = "-U" },
}

local config = {
  enabled = nil,
  executable = "rmux",
}

local function notify_error(message)
  vim.schedule(function()
    vim.notify("rmux.nvim: " .. message, vim.log.levels.ERROR)
  end)
end

local function is_rmux_session()
  if config.enabled ~= nil then
    return config.enabled
  end

  return (vim.env.RMUX ~= nil and vim.env.RMUX ~= "") or vim.env.TERM_PROGRAM == "rmux"
end

local function select_rmux_pane(flag)
  if not is_rmux_session() then
    return false, "boundary"
  end

  if vim.fn.executable(config.executable) ~= 1 then
    notify_error("rmux executable not found: " .. config.executable)
    return false, "error"
  end

  local command = { config.executable, "select-pane", flag }
  local ok, error_message = pcall(vim.system, command, { text = true }, function(result)
    if result.code ~= 0 then
      local detail = (result.stderr or ""):gsub("%s+$", "")
      if detail == "" then
        detail = "exit code " .. result.code
      end
      notify_error("failed to select pane: " .. detail)
    end
  end)

  if not ok then
    notify_error("failed to start rmux: " .. tostring(error_message))
    return false, "error"
  end

  return true, "rmux"
end

function M.setup(options)
  options = options or {}

  if options.enabled ~= nil then
    assert(type(options.enabled) == "boolean", "rmux.nvim: enabled must be a boolean")
    config.enabled = options.enabled
  end

  if options.executable ~= nil then
    assert(
      type(options.executable) == "string" and options.executable ~= "",
      "rmux.nvim: executable must be a non-empty string"
    )
    config.executable = options.executable
  end
end

function M.move_to(direction)
  local target = directions[direction]
  assert(target ~= nil, "rmux.nvim: invalid direction: " .. tostring(direction))

  local previous_window = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(target.nvim)

  if vim.api.nvim_get_current_win() ~= previous_window then
    local buffer = vim.api.nvim_get_current_buf()
    local modified = vim.api.nvim_get_option_value("modified", { buf = buffer })
    if not modified then
      vim.api.nvim_cmd({ cmd = "edit", bang = true }, {})
    end
    return true, "nvim"
  end

  return select_rmux_pane(target.rmux)
end

function M.move_left()
  return M.move_to("left")
end

function M.move_bottom()
  return M.move_to("bottom")
end

function M.move_top()
  return M.move_to("top")
end

function M.move_right()
  return M.move_to("right")
end

return M
