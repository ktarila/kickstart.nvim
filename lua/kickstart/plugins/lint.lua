return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        php = { 'phpcs' },
      }

      -- Project root for a buffer. `.git` is checked before `composer.json`
      -- so a file opened from `vendor/` still resolves to the real project
      -- rather than the package's own `composer.json`.
      local function project_root(bufnr)
        return vim.fs.root(bufnr, { '.git' }) or vim.fs.root(bufnr, { 'composer.json' }) or vim.fn.getcwd()
      end

      -- nvim-lint's bundled `phpcs` and `phpstan` definitions resolve
      -- `vendor/bin/<tool>` relative to the process cwd, and both tools walk up
      -- from cwd to find their ruleset (`phpcs.xml`, `phpstan.neon`). Running
      -- every lint with cwd set to the project root therefore gives the same
      -- binary and the same config as the git hooks, with no path juggling here.
      local function lint_opts(bufnr)
        return { cwd = project_root(bufnr) }
      end

      -- phpcs 3 defaults to the PEAR standard when no ruleset is found, which
      -- is noisy on a project that has none; fall back to PSR12 instead.
      local phpcs_rulesets = { '.phpcs.xml', 'phpcs.xml', '.phpcs.xml.dist', 'phpcs.xml.dist' }
      local phpcs = lint.linters.phpcs
      lint.linters.phpcs = function()
        local args = vim.deepcopy(phpcs.args)
        if not vim.fs.root(0, phpcs_rulesets) then
          table.insert(args, 1, '--standard=PSR12')
        end
        return vim.tbl_extend('force', phpcs, { args = args })
      end

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function(ev)
          lint.try_lint(nil, lint_opts(ev.buf))
        end,
      })

      -- PHPStan reads the file from disk and takes a second or two even with
      -- its result cache, so it only runs on write, and only in projects that
      -- ship it.
      vim.api.nvim_create_autocmd('BufWritePost', {
        group = lint_augroup,
        pattern = '*.php',
        callback = function(ev)
          local root = project_root(ev.buf)
          if vim.uv.fs_stat(root .. '/vendor/bin/phpstan') then
            lint.try_lint('phpstan', { cwd = root })
          end
        end,
      })
    end,
  },
}
