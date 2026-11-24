-- Twig indentation on top of treesitter.
--
-- The twig grammar is flat: `{% if %}` ... `{% endif %}` are sibling
-- `statement_directive` nodes with no wrapping block node, so an
-- `indents.scm` can't express "indent between them". nvim-treesitter still
-- indents the HTML (injected into `content`), so this takes that answer and
-- adds one shiftwidth per twig block that is open at the line.
--
-- A tag `X` is treated as a block opener when the buffer contains a matching
-- `endX` somewhere, so custom tags (`{% component %}`, `{% cache %}` ...)
-- work without being listed. `else`/`elseif` are branches: dedented
-- themselves, depth unchanged.
local ts = vim.treesitter

local M = {}

local BRANCH = { ['else'] = true, ['elseif'] = true }

-- The statement inside a `statement_directive` (`if_statement`,
-- `tag_statement`, ...) and its keyword text. The directive node itself
-- swallows the blank lines before `{%`, so rows are taken from the statement.
---@return string? name, TSNode? statement
local function statement(directive, bufnr)
  local stmt = directive:named_child(0)
  if not stmt then
    return
  end
  local kw = stmt:named_child(0)
  if not kw then
    return
  end
  return ts.get_node_text(kw, bufnr), stmt
end

-- `{% block title 'x' %}` and `{% set foo = 1 %}` are one-liners, not blocks.
local function is_inline(stmt, name)
  if name == 'block' then
    return stmt:named_child_count() > 2
  end
  if name == 'set' then
    for child in stmt:iter_children() do
      if child:type() == '=' then
        return true
      end
    end
  end
  return false
end

---@return TSNode[] directives, table<string,boolean> closers
local function collect(bufnr, twig_root)
  local directives, closers = {}, {}
  local query = ts.query.parse('twig', '(statement_directive) @d')
  for _, node in query:iter_captures(twig_root, bufnr) do
    local name, stmt = statement(node, bufnr)
    if name then
      directives[#directives + 1] = { node = stmt, name = name }
      local opener = name:match('^end(.+)$')
      if opener then
        closers[opener] = true
      end
    end
  end
  return directives, closers
end

-- Number of twig blocks open at `lnum` (1-indexed), and whether that line
-- itself starts with a closer/branch directive (which should sit one level
-- out).
local function depth_at(bufnr, twig_root, lnum)
  local directives, closers = collect(bufnr, twig_root)
  local depth = 0
  local dedent_self = false
  for _, d in ipairs(directives) do
    local srow = d.node:start()
    local name = d.name
    if srow < lnum - 1 then
      if name:match('^end') then
        depth = depth - 1
      elseif closers[name] and not is_inline(d.node, name) then
        depth = depth + 1
      end
    elseif srow == lnum - 1 then
      if name:match('^end') or BRANCH[name] then
        dedent_self = true
      end
      break
    else
      break
    end
  end
  return math.max(depth, 0), dedent_self
end

-- Twig depth the line is indented by, once its own closer/branch is taken
-- into account.
local function effective_depth(bufnr, twig_root, lnum)
  local depth, dedent_self = depth_at(bufnr, twig_root, lnum)
  if dedent_self then
    depth = depth - 1
  end
  return math.max(depth, 0)
end

-- Row (0-indexed) the injected tree that nvim-treesitter will use for `lnum`
-- starts on, or nil when that is the top-level twig tree. Mirrors the tree
-- selection in nvim-treesitter's `get_indent`.
local function injected_root_row(parser, lnum)
  local root
  parser:for_each_tree(function(tstree, tree)
    if not tstree or require('nvim-treesitter.indent').comment_parsers[tree:lang()] then
      return
    end
    local local_root = tstree:root()
    if ts.is_in_node_range(local_root, lnum - 1, 0) then
      if not root or root:byte_length() >= local_root:byte_length() then
        root = local_root
      end
    end
  end)
  if root and root:start() ~= 0 then
    return (root:start())
  end
end

---@param lnum integer 1-indexed
---@return integer
function M.get_indent(lnum)
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, parser = pcall(ts.get_parser, bufnr, 'twig')
  if not ok or not parser then
    return -1
  end
  parser:parse(true)
  local twig_root = parser:trees()[1] and parser:trees()[1]:root()
  if not twig_root then
    return -1
  end

  local sw = vim.fn.shiftwidth()
  local depth = effective_depth(bufnr, twig_root, lnum)

  local base = require('nvim-treesitter.indent').get_indent(lnum)
  if base < 0 then
    -- No HTML answer (e.g. only directives so far): keep the previous
    -- line's indent and apply the change in twig depth since then.
    local prev = vim.fn.prevnonblank(lnum - 1)
    if prev == 0 then
      return depth * sw
    end
    local prev_depth = effective_depth(bufnr, twig_root, prev)
    return math.max(vim.fn.indent(prev) + (depth - prev_depth) * sw, 0)
  end

  -- For an injected (HTML) tree nvim-treesitter starts from the indent of
  -- the tree's first line, which already carries that line's twig depth.
  local root_row = injected_root_row(parser, lnum)
  if root_row == lnum - 1 then
    -- The tree's own first line: nvim-treesitter just echoes its current
    -- indent back, and HTML top level contributes nothing anyway.
    return depth * sw
  elseif root_row then
    depth = depth - effective_depth(bufnr, twig_root, root_row + 1)
  end
  return math.max(base + depth * sw, 0)
end

function M.indentexpr()
  return M.get_indent(vim.v.lnum)
end

return M
