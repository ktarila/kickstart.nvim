-- see lua/custom/twig_indent.lua
vim.bo.indentexpr = "v:lua.require'custom.twig_indent'.indentexpr()"
vim.bo.indentkeys = '0{,0},0),0],!^F,o,O,e,=%},=%-},=%~}'
