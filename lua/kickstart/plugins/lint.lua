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

      -- Define a function to find the phpcs.xml in the working directory
      local function find_phpcs_config()
        local working_dir = vim.fn.getcwd()
        local phpcs_file = vim.fn.findfile('phpcs.xml', working_dir .. ';')

        if phpcs_file == '' then
          -- vim.notify('phpcs.xml not found in working directory: ' .. working_dir .. '. Using PSR12 coding standard.', vim.log.levels.WARN)
          return nil -- Return nil if not found
        else
          -- vim.notify('Using phpcs.xml located at: ' .. phpcs_file .. ' (working directory: ' .. working_dir .. ')', vim.log.levels.INFO)
          return phpcs_file
        end
      end

      -- Customize phpcs arguments to use the local standard file or PSR12
      local phpcs_config = find_phpcs_config()
      if phpcs_config then
        require('lint').linters.phpcs.args = {
          '--standard=' .. phpcs_config,
          '--report=json',
          '-q',
          '-',
        }
      else
        require('lint').linters.phpcs.args = {
          '--standard=PSR12', -- Use PSR12 as the fallback standard
          '--report=json',
          '-q',
          '-',
        }
      end

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },
}
