return {
  {
    "ginkohub/translate.nvim",
    event = "VeryLazy",
    opts = {
      default_backend = "google",
      default_target = "en",
      default_source = "auto",
    },
    keys = {
      { "te", ":TrR en<CR>", mode = "v", desc = "Translate selection to English" },
      { "tf", ":TrR fr<CR>", mode = "v", desc = "Translate selection to French" },
    },
  },
}