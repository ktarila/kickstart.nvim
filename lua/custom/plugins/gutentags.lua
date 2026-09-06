return {
  'ludovicchabant/vim-gutentags',
  event = { 'BufReadPost', 'BufNewFile' },
  init = function()
    -- Write every index under a cache directory instead of dropping a `tags`
    -- file into each project.
    local cache = vim.fn.stdpath 'cache' .. '/gutentags'
    vim.fn.mkdir(cache, 'p')
    vim.g.gutentags_cache_dir = cache

    vim.g.gutentags_project_root = { '.git', 'go.mod', 'package.json', 'composer.json' }
    vim.g.gutentags_generate_on_new = 1
    vim.g.gutentags_generate_on_missing = 1
    vim.g.gutentags_generate_on_write = 1
    vim.g.gutentags_generate_on_empty_buffer = 0

    -- Exuberant ctags only half-parses Postgres, so `CREATE FUNCTION` and
    -- friends are matched by hand in `ctags/pgsql.ctags`, which hands `.sql`
    -- to those rules. That makes a Go string like `app.consume_quota` jump to
    -- the migration defining it (`<leader>gs`, or plain `<C-]>`).
    --
    -- The rules live in an options file rather than inline here because
    -- gutentags' shell wrapper pastes these arguments in unquoted: spaces
    -- would split one regex into several, and `\4` backreferences would be
    -- swallowed as escape sequences.
    vim.g.gutentags_ctags_extra_args = {
      '--fields=+l',
      '--options=' .. vim.fn.stdpath 'config' .. '/ctags/pgsql.ctags',
    }

    vim.g.gutentags_ctags_exclude = {
      '.git',
      'node_modules',
      'vendor',
      'bin',
      'dist',
      'build',
      '*.min.js',
      '.data',
      'deploy/.data',
    }
  end,
}
