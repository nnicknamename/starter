return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {},
        ltex_plus = false,
        ltex = false,
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "markdown", "markdown_inline" })
      end
    end,
  },
  {
    "jghauser/follow-md-links.nvim",
    ft = { "markdown" },
    config = function()
      local function follow_md_link()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1
        local start_pos, end_pos = line:find("%b[]%b()")
        while start_pos do
          if col >= start_pos and col <= end_pos then
            local target = line:sub(start_pos, end_pos):match("%((.-)%)")
            if target then
              if target:sub(1, 1) == "#" then
                local heading = target:sub(2):gsub("%-+", " "):gsub("_", " ")
                vim.fn.search("\\c^#\\+ *" .. heading, "w")
                return
              elseif target:match("^https?://") then
                vim.ui.open(target)
                return
              else
                local dir = vim.fn.expand("%:p:h"):gsub("\\", "/")
                local file = target
                local line_num
                if file:match(":(%d+)$") then
                  line_num = tonumber(file:match(":(%d+)$"))
                  file = file:gsub(":%d+$", "")
                end
                if not (file:match("^/") or file:match("^%a:")) then
                  file = dir .. "/" .. file
                end
                file = file:gsub("\\", "/")
                if vim.fn.filereadable(file) == 1 then
                  vim.cmd("edit " .. vim.fn.fnameescape(file))
                  if line_num then
                    vim.api.nvim_win_set_cursor(0, { line_num, 0 })
                  end
                  return
                else
                  vim.notify("File not found: " .. file, vim.log.levels.WARN)
                  return
                end
              end
            end
          end
          start_pos, end_pos = line:find("%b[]%b()", end_pos + 1)
        end
        vim.notify("No markdown link under cursor", vim.log.levels.INFO)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          if vim.bo[args.buf].filetype ~= "markdown" then return end
          vim.schedule(function()
            vim.keymap.set("n", "gd", follow_md_link, {
              buffer = args.buf,
              desc = "Follow markdown link",
              silent = true,
            })
          end)
        end,
      })

      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.md",
        callback = function(args)
          vim.schedule(function()
            vim.keymap.set("n", "gd", follow_md_link, {
              buffer = args.buf,
              desc = "Follow markdown link",
              silent = true,
            })
          end)
        end,
      })
    end,
  },
}
