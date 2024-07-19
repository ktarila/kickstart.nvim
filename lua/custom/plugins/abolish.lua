return {
  'tpope/vim-abolish',
  cond = 'true',
  config = function()
    vim.cmd 'Abolish cosnt const'
  end,
}
