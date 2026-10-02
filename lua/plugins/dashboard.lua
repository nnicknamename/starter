return {
  { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },
  {
    "nvimdev/dashboard-nvim",
    lazy = false,
    dependencies = {
      { "juansalvatore/git-dashboard-nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    opts = function()
      local dashboard_config = {
        fallback_header = "",
        top_padding = 0,
        bottom_padding = 0,
        use_git_username_as_author = false,
        author = "",
        branch = "main",
        gap = " ",
        centered = true,
        day_label_gap = " ",
        empty = " ",
        empty_square = "□",
        filled_squares = { "■", "■", "■", "■", "■", "■" },
        hide_cursor = false,
        is_horizontal = true,
        show_contributions_count = true,
        show_only_weeks_with_commits = false,
        title = "repo_name",
        show_current_branch = true,
        days = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
        months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
        use_current_branch = true,
        basepoints = { "master", "main" },
        colors = (function()
          local function parse_color(v)
            if type(v) == "table" then
              return v[1], v[2], v[3]
            end
            if type(v) == "number" then
              return math.floor(v / 65536) % 256, math.floor(v / 256) % 256, v % 256
            end
            if type(v) == "string" and v:sub(1, 1) == "#" then
              return tonumber(v:sub(2, 3), 16), tonumber(v:sub(4, 5), 16), tonumber(v:sub(6, 7), 16)
            end
          end
          local function to_hex(r, g, b)
            return string.format("#%02x%02x%02x", r, g, b)
          end
          local function blend(v1, v2, ratio)
            local r1, g1, b1 = parse_color(v1)
            local r2, g2, b2 = parse_color(v2)
            if not r1 or not r2 then
              return nil
            end
            return to_hex(
              math.floor(r1 + (r2 - r1) * ratio),
              math.floor(g1 + (g2 - g1) * ratio),
              math.floor(b1 + (b2 - b1) * ratio)
            )
          end
          local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
          local accent = vim.api.nvim_get_hl(0, { name = "Keyword", link = false }).fg
            or vim.api.nvim_get_hl(0, { name = "Function", link = false }).fg
            or vim.api.nvim_get_hl(0, { name = "Identifier", link = false }).fg
          if not bg or not accent then
            return nil
          end
          local r, g, b = parse_color(accent)
          if not r then
            accent = { 0x7a, 0xa2, 0xf7 }
          else
            accent = { r, g, b }
          end
          return {
            days_and_months_labels = blend(bg, accent, 0.6),
            empty_square_highlight = blend(bg, accent, 0.3),
            filled_square_highlights = {
              blend(bg, accent, 0.3),
              blend(bg, accent, 0.45),
              blend(bg, accent, 0.6),
              blend(bg, accent, 0.75),
              blend(bg, accent, 0.9),
              blend(bg, accent, 1.0),
            },
            branch_highlight = blend(bg, accent, 0.6),
            dashboard_title = blend(bg, accent, 0.8),
          }
        end)() or {
          days_and_months_labels = "#7eac6f",
          empty_square_highlight = "#54734a",
          filled_square_highlights = { "#2a3925", "#54734a", "#7eac6f", "#98c689", "#afd2a3", "#bad9b0" },
          branch_highlight = "#8DC07C",
          dashboard_title = "#a3cc96",
        },
      }

      -- Replace git-dashboard-nvim's highlight system with nvim_buf_add_highlight
      -- (syntax match doesn't work in LazyVim since Vim syntax is disabled)
      local highlights = require("git-dashboard-nvim.highlights")
      highlights.add_highlights = function(config, current_date_info, branch_label, title)
        vim.cmd("match none")
        vim.cmd("highlight clear DashboardHeader")

        local function add_group(group_name, fg_color)
          vim.cmd("highlight " .. group_name .. " guifg=" .. fg_color)
        end

        add_group("DashboardHeaderEmptySquare", config.colors.empty_square_highlight)
        for i = 1, #config.days do
          add_group("DashboardHeaderDay" .. i, config.colors.days_and_months_labels)
        end
        for i = 1, current_date_info.current_month do
          add_group("DashboardHeaderMonth", config.colors.days_and_months_labels)
        end
        for i = 1, #config.filled_squares do
          add_group("DashboardHeaderFilledSquare" .. i, config.colors.filled_square_highlights[i])
        end
        add_group("DashboardHeaderTitle", config.colors.dashboard_title)
        add_group("DashboardHeaderBranch", config.colors.branch_highlight)

        vim.schedule(function()
          local bufnr = vim.api.nvim_get_current_buf()
          if bufnr == nil or bufnr == 0 then
            return
          end
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          for line_idx, line in ipairs(lines) do
            if type(line) ~= "string" then
              break
            end
            for sq_idx, square in ipairs(config.filled_squares) do
              local col = 0
              while true do
                local start = line:find(vim.pesc(square), col + 1)
                if start == nil then
                  break
                end
                vim.api.nvim_buf_add_highlight(
                  bufnr,
                  -1,
                  "DashboardHeaderFilledSquare" .. sq_idx,
                  line_idx - 1,
                  start - 1,
                  start - 1 + #square
                )
                col = start
              end
            end
            local col = 0
            while true do
              local start = line:find(vim.pesc(config.empty_square), col + 1)
              if start == nil then
                break
              end
              vim.api.nvim_buf_add_highlight(
                bufnr,
                -1,
                "DashboardHeaderEmptySquare",
                line_idx - 1,
                start - 1,
                start - 1 + #config.empty_square
              )
              col = start
            end
          end
        end)
      end

      local git_dashboard = require("git-dashboard-nvim").setup(dashboard_config)

      local opts = {
        theme = "doom",
        hide = {
          statusline = true,
        },
        config = {
          header = git_dashboard,
          center = {
            {
              action = "lua LazyVim.pick()()",
              desc = " Find File",
              icon = " ",
              key = "f",
            },
            {
              action = "ene | startinsert",
              desc = " New File",
              icon = " ",
              key = "n",
            },
            {
              action = 'lua LazyVim.pick("oldfiles")()',
              desc = " Recent Files",
              icon = " ",
              key = "r",
            },
            {
              action = 'lua LazyVim.pick("live_grep")()',
              desc = " Find Text",
              icon = " ",
              key = "g",
            },
            {
              action = "lua LazyVim.pick.config_files()()",
              desc = " Config",
              icon = " ",
              key = "c",
            },
            {
              action = 'lua require("persistence").load()',
              desc = " Restore Session",
              icon = " ",
              key = "s",
            },
            {
              action = "LazyExtras",
              desc = " Lazy Extras",
              icon = " ",
              key = "x",
            },
            {
              action = "Lazy",
              desc = " Lazy",
              icon = "󰒲 ",
              key = "l",
            },
            {
              action = function()
                vim.api.nvim_input("<cmd>qa<cr>")
              end,
              desc = " Quit",
              icon = " ",
              key = "q",
            },
          },
          footer = function()
            local stats = require("lazy").stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
          end,
        },
      }

      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
        button.key_format = "  %s"
      end

      if vim.o.filetype == "lazy" then
        vim.api.nvim_create_autocmd("WinClosed", {
          pattern = tostring(vim.api.nvim_get_current_win()),
          once = true,
          callback = function()
            vim.schedule(function()
              vim.api.nvim_exec_autocmds("UIEnter", { group = "dashboard" })
            end)
          end,
        })
      end

      return opts
    end,
  },
}
