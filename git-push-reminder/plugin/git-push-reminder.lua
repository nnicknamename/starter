local defaults = {
  reminder_interval = 30 * 60 * 1000,
  unpushed_threshold = 60 * 60,
  uncommitted_threshold = 60 * 60,
}

local function format_duration(elapsed)
  local hours = math.floor(elapsed / 3600)
  local minutes = math.floor((elapsed % 3600) / 60)
  local parts = {}
  if hours > 0 then
    table.insert(parts, hours .. "h")
  end
  table.insert(parts, minutes .. "m")
  return table.concat(parts, " ")
end

local function show_floating_notification(kind, elapsed, action)
  local icon = kind == "unpushed" and "󰛃" or "✎"
  local title = kind == "unpushed" and "Unpushed Commits" or "Uncommitted Changes"
  local hl = kind == "unpushed" and "DiagnosticWarn" or "DiagnosticHint"
  local ago = format_duration(elapsed)

  local lines = {
    "",
    "  " .. icon .. "  " .. title,
    "",
    "  " .. ago .. " since last push",
    "",
    "  " .. action,
    "",
  }

  local width = 52
  local height = #lines
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { silent = true, noremap = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", "<cmd>close<CR>", { silent = true, noremap = true })

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 2,
    style = "minimal",
    border = "rounded",
    title = " Git Reminder ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_win_set_option(win, "winhl", "NormalFloat:" .. hl)

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      pcall(vim.api.nvim_win_close, win, true)
    end,
  })

  vim.api.nvim_buf_attach(buf, false, {
    on_detach = function()
      pcall(vim.api.nvim_win_close, win, true)
    end,
  })
end

local function get_last_push_ts()
  local lines = vim.fn.systemlist(
    'git log @{u} --format="%ct" --max-count=1'
  )
  if vim.v.shell_error ~= 0 or #lines == 0 then
    return nil
  end
  return tonumber(lines[1])
end

local function has_unpushed_commits()
  local lines = vim.fn.systemlist("git rev-list --count --branches --not --remotes")
  if vim.v.shell_error ~= 0 or #lines == 0 then
    return false
  end
  return tonumber(lines[1]) > 0
end

local function has_uncommitted_changes()
  local lines = vim.fn.systemlist("git status --porcelain")
  return vim.v.shell_error == 0 and #lines > 0
end

local function check_git()
  if vim.fn.executable("git") ~= 1 then
    return
  end

  vim.fn.system("git rev-parse --git-dir")
  if vim.v.shell_error ~= 0 then
    return
  end

  local now = vim.fn.localtime()
  local last_push_ts = get_last_push_ts()

  if not last_push_ts then
    return
  end

  if has_unpushed_commits() then
    local elapsed = now - last_push_ts
    if elapsed > defaults.unpushed_threshold then
      show_floating_notification("unpushed", elapsed, "Run :Git push to sync your changes")
    end
  end

  if has_uncommitted_changes() then
    local elapsed = now - last_push_ts
    if elapsed > defaults.uncommitted_threshold then
      show_floating_notification("push_uncommitted", elapsed, "Run :Git commit then push to sync your changes")
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("GitPushReminder", { clear = true }),
  callback = function()
    vim.defer_fn(check_git, 5000)
  end,
})

local timer = (vim.uv or vim.loop).new_timer()
timer:start(defaults.reminder_interval, defaults.reminder_interval, vim.schedule_wrap(check_git))

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("GitPushReminderCleanup", { clear = true }),
  once = true,
  callback = function()
    if timer and not timer:is_closing() then
      timer:close()
    end
  end,
})
