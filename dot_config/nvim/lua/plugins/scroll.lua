return {
  {
    'declancm/cinnamon.nvim',
    lazy = false,
    opts = {
      keyframes = 180,       -- duration in ms
      max_length = 500,      -- don't animate very long jumps
      scroll_limit = 150,    -- max lines to animate
    },
  },
}