return {
  {
    'declancm/cinnamon.nvim',
    lazy = false,
    opts = {
      keymaps = {
        basic = true,   -- smooth Ctrl-D/Ctrl-U, G/gg, etc.
        extra = true,   -- smooth n/N, */#, %, etc.
      },
      options = {
        delay = 5,          -- ms between steps
        step_size = {
          vertical = 1,
          horizontal = 2,
        },
        max_delta = {
          line = 150,       -- max lines to animate
          column = false,   -- no column limit
          time = 1000,      -- max animation duration in ms
        },
        mode = "cursor",    -- scroll cursor smoothly
      },
    },
  },
}