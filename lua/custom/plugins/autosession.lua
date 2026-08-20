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

      vim.keymap.set('n', '<leader>ls', require('auto-session.session-lens').search_session, {
        noremap = true,
      })
    end,
  },
}
