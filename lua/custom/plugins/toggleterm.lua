return {
  'akinsho/toggleterm.nvim',
  version = '*', -- Use the latest version
  opts = {
    size = 20,
    open_mapping = [[<c-\>]],
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    persist_size = true,
    direction = 'float',
    close_on_exit = true,
    shell = vim.o.shell,
    float_opts = {
      border = 'curved',
      width = 120,
      height = 30,
      winblend = 3,
      highlights = {
        border = 'Normal',
        background = 'Normal',
      },
    },
  },
  config = function(_, opts)
    require('toggleterm').setup(opts)
  end,
  keys = {
    { '<Leader>.t', '<Cmd>ToggleTerm direction=float<CR>', noremap = true, silent = true, desc = 'Open ToggleTerm floating window' },
    { '<Leader>.g', '<Cmd>ToggleTerm direction=float<CR>lazygit<CR>', noremap = true, silent = true, desc = 'Open LazyGit floating window' },
  },
}
