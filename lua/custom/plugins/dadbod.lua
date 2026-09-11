-- Database client: schema browser, saved queries and result buffers
-- (`:DBUI`), with table/column completion in SQL buffers.
return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
  keys = {
    { '<leader>db', '<cmd>DBUIToggle<CR>', desc = '[D]ata[b]ase UI' },
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = vim.g.have_nerd_font and 1 or 0
    vim.g.db_ui_save_location = vim.fn.stdpath 'data' .. '/db_ui'

    -- Symfony keeps its connection in `DATABASE_URL`; `.env.local` overrides
    -- `.env`. Read it from the project root when a connection is opened, so
    -- the same entry works in whichever project the session is in.
    local function symfony_database_url()
      local root = vim.fs.root(0, { '.git' }) or vim.fs.root(0, { 'composer.json' }) or vim.fn.getcwd()
      for _, env in ipairs { '.env.local', '.env' } do
        local f = io.open(root .. '/' .. env)
        if f then
          local url
          for line in f:lines() do
            url = line:match '^DATABASE_URL="?([^"]+)"?' or url
          end
          f:close()
          -- Doctrine-only query params (`serverVersion`, `charset`) are not
          -- connection options; strip them before handing the URL to psql.
          -- `%kernel.project_dir%` placeholders (sqlite) can't be resolved here.
          if url and not url:find('%', 1, true) then
            return (url:gsub('%?.*$', ''))
          end
        end
      end
      error('No DATABASE_URL found in ' .. root .. '/.env.local or .env')
    end

    vim.g.dbs = {
      { name = 'symfony (.env)', url = symfony_database_url },
    }
  end,
  config = function()
    -- Table and column completion for SQL buffers (DBUI query buffers included).
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('dadbod-completion', { clear = true }),
      pattern = { 'sql', 'mysql', 'plsql' },
      callback = function()
        require('cmp').setup.buffer {
          sources = {
            { name = 'vim-dadbod-completion' },
            { name = 'luasnip' },
          },
        }
      end,
    })
  end,
}
