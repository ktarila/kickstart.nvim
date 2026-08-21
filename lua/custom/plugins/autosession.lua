return {
  {
    'rmagatti/auto-session',
    dependencies = {
      'nvim-telescope/telescope.nvim', -- Only needed if you want to use sesssion lens
    },
    config = function()
      -- `localoptions` keeps filetype/highlighting correct after a session restore.
      vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

      require('auto-session').setup {
        suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
      }

      -- The old `auto-session.session-lens` module is gone; the picker now lives
      -- behind `auto-session.pickers`, which resolves telescope -> fzf -> snacks
      -- -> `vim.ui.select` at invoke time. Going through the command rather than
      -- a direct `require` keeps that resolution lazy.
      vim.keymap.set('n', '<leader>ls', '<cmd>AutoSession search<CR>', {
        noremap = true,
        desc = '[L]ist [S]essions',
      })
    end,
  },
}
