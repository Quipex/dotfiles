return {
  {
    'declancm/cinnamon.nvim',
    lazy = false,
    opts = {
      keymaps = {
        basic = true,
        extra = true,
      },
      options = {
        delay = 7,            -- ms between steps (slightly higher = fewer renders)
        step_size = {
          vertical = 2,       -- 2 lines per step instead of 1
          horizontal = 2,
        },
        max_delta = {
          line = 100,         -- skip animation for jumps > 100 lines
          column = false,
          time = 300,         -- max 300ms per animation (was 1000)
        },
        mode = "cursor",
      },
    },
  },
}