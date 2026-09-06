---@brief
---
--- https://github.com/symfony/language-tools
---
--- Symfony-aware completion, navigation, references, diagnostics, code actions,
--- rename support and code lenses alongside a general PHP language server.
---
--- Install the `symfony-lsp` executable from a release, then make it
--- available on `PATH`.
---
--- The server asks before executing application code for runtime indexing. Set
--- `init_options.workspaceTrust` explicitly only for trusted workspaces.
---
--- Only keys the server actually reads are set below. The recognised project
--- settings are `phpCommand`, `containerProjectRoot`, `environment`, `debug`,
--- `runtimeIndexing`, `releaseMetadata`, `bridgeTimeout`, `translationDiagnostics`
--- and `excludePaths`; `workspaceTrust` and `projectRoots` are handled as
--- initialization options. Anything else is dropped silently, so a typo here is
--- invisible rather than an error.
---
--- On startup the server rebuilds two indexes. The *source* index is cached in
--- `var/symfony-lsp/<version>/index/source.jsonl` and reused (~0.6s warm against
--- ~6.5s cold). The *runtime* index is not: `ProjectRuntimeInitializer` reads its
--- persisted snapshot only from the failure path, so `bridge.php` boots the
--- kernel and re-runs every debug section on each start -- ~6.5s here, every
--- time, with no setting to avoid it short of `runtimeIndexing = false` (which
--- costs routes, container, twig-component and translation awareness). It does
--- not block editing: diagnostics land at ~0.3s and the runtime data enriches
--- them later.

---@type vim.lsp.Config
return {
  cmd = { 'symfony-lsp' },
  filetypes = { 'php', 'twig', 'yaml', 'json', 'xml', 'javascript', 'typescript', 'env' },
  -- Priority tiers, not a flat list: a Symfony app ships ~200 `composer.json`
  -- files under `vendor/`, and a flat list makes the *nearest* one win -- so a
  -- `gd` into vendor code roots a second client at, say,
  -- `vendor/symfony/console`. It indexes nothing (the server needs
  -- `symfony/framework-bundle` plus `bin/console` to recognise a project) but
  -- still costs a ~90MB process. Checking `.git` first pins every buffer in the
  -- repo to the one real root; `composer.json` stays as the fallback for a
  -- project that is not a git checkout.
  root_markers = { { '.git' }, { 'composer.json' } },
  workspace_required = true,
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
  init_options = {
    phpCommand = { 'php' },
    -- Runtime indexing runs `bin/console` through the generated bridge, so the
    -- server asks permission before it will do that. It keeps no record of the
    -- answer -- there is no trust file under `var/symfony-lsp/` or anywhere in
    -- $XDG_* -- so trust lives only in the server process and every restart
    -- asks again. Declaring it here answers once, for every project.
    workspaceTrust = true,
    environment = 'dev',
    -- Not optional: the server refuses to build the runtime index outside debug
    -- mode (`runtimeIndexing()` is `debug && runtimeIndexingRequested()`), and
    -- `initialize()` throws without it.
    debug = true,
    runtimeIndexing = true,
  },
  -- Answered on the server's `workspace/configuration` request. Overlaps
  -- `init_options` for most keys, but `translationDiagnostics` is read from
  -- here only, so the block has to stay.
  settings = {
    symfonyLsp = {
      phpCommand = { 'php' },
      environment = 'dev',
      debug = true,
      runtimeIndexing = true,
      translationDiagnostics = false,
    },
  },
  commands = {
    ['editor.action.showReferences'] = function(command, ctx)
      local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
      local arguments = command.arguments or {}
      local uri = arguments[1]
      local position = arguments[2]
      local references = arguments[3]
      if type(uri) ~= 'string' or type(position) ~= 'table' or type(references) ~= 'table' then
        vim.notify(
          'Symfony Language Tools returned an invalid reference command.',
          vim.log.levels.ERROR
        )
        return
      end

      local items = vim.lsp.util.locations_to_items(references, client.offset_encoding)
      vim.fn.setqflist({}, ' ', {
        title = command.title,
        items = items,
        context = {
          command = command,
          bufnr = ctx.bufnr,
        },
      })
      vim.lsp.util.show_document({
        uri = uri,
        range = {
          start = position,
          ['end'] = position,
        },
      }, client.offset_encoding)
      vim.cmd('botright copen')
    end,
  },
}
