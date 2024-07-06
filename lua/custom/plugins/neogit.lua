return {
  'NeogitOrg/neogit',
  tag = 'v0.0.1',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration

    -- Only one of these is needed, not both.
    'nvim-telescope/telescope.nvim', -- optional
  },
  config = function()
    require('neogit').setup()
  end,
  keys = {
    -- Add key mappings specific to neogit
    { '<Leader>Gg', '<Cmd>Neogit<CR>', noremap = true, silent = true, desc = 'Open Neogit' },
    { '<Leader>Gc', '<Cmd>Neogit commit<CR>', noremap = true, silent = true, desc = 'Commit' },
    { '<Leader>Gp', '<Cmd>Neogit pull<CR>', noremap = true, silent = true, desc = 'Pull' },
    { '<Leader>GP', '<Cmd>Neogit push<CR>', noremap = true, silent = true, desc = 'Push' },
    { '<Leader>Gs', '<Cmd>Neogit status<CR>', noremap = true, silent = true, desc = 'Status' },
  },
}
