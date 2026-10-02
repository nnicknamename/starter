-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local wezterm_directions = { h = "Left", j = "Down", k = "Up", l = "Right" }
for key, dir in pairs(wezterm_directions) do
  vim.keymap.set({ "n", "t" }, "<C-" .. key .. ">", function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. key)
    if vim.api.nvim_get_current_win() == win then
      vim.fn.system("wezterm cli activate-pane-direction --" .. dir)
    end
  end, { silent = true })
end
