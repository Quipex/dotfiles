return {
  -- Package manager for LSP servers, formatters, etc.
  { 'williamboman/mason.nvim', build = ':MasonUpdate', opts = {} },

  -- Bridges mason with lspconfig; auto-installs the servers listed below.
  -- automatic_enable is OFF: we start servers ourselves (nvim-jdtls for Java,
  -- an explicit FileType autocmd for Kotlin) so there is no double-attach.
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      ensure_installed = { 'jdtls', 'kotlin_language_server' },
      automatic_enable = false,
    },
  },

  -- Kotlin LSP (hyde is Kotlin-heavy).
  -- We start it the same robust way nvim-jdtls starts jdtls: a FileType autocmd
  -- that calls vim.lsp.start directly with an explicit cmd + root_dir. This
  -- avoids the deprecated lspconfig.<server>.setup() path (unreliable in recent
  -- nvim-lspconfig) and the vim.lsp.enable indirection. mason-lspconfig still
  -- installs the `kotlin-language-server` binary (see ensure_installed above)
  -- and mason.nvim puts it on PATH at startup.
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'williamboman/mason-lspconfig.nvim' },
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'kotlin',
        group = vim.api.nvim_create_augroup('KotlinLsp', { clear = true }),
        callback = function(event)
          local cmd = vim.fn.exepath('kotlin-language-server')
          if cmd == '' then return end -- server not installed yet (run :Mason)
          local root = vim.fs.dirname(vim.fs.find(
            { 'gradlew', '.git', 'mvnw', 'build.gradle', 'build.gradle.kts' },
            { upward = true }
          )[1])
          vim.lsp.start({
            name = 'kotlin_language_server',
            cmd = { cmd },
            -- hyde is 26k Kotlin files / 164 Gradle modules. fwcd KLS compiles
            -- the whole source path on lintAll and OOMs on the JVM default heap
            -- (see ~/.local/state/nvim/lsp.log: java.lang.OutOfMemoryError).
            -- The Gradle launcher reads KOTLIN_LANGUAGE_SERVER_OPTS and appends it
            -- to the java invocation; cmd_env merges with the current env
            -- (PATH/JAVA_HOME preserved). Bump to 12g if it still OOMs.
            cmd_env = { KOTLIN_LANGUAGE_SERVER_OPTS = '-Xmx8g' },
            root_dir = root,
            settings = { kotlin = { compiler = { jvm = { target = '21' } } } },
          })
        end,
      })
    end,
  },

  -- Java LSP. nvim-jdtls is the community-recommended way to run jdtls:
  -- it gives each project its own workspace dir so imports don't clash.
  -- jdtls itself is installed by mason (see ensure_installed above).
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    config = function()
      local project = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
      local workspace = vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project
      local root = vim.fs.dirname(vim.fs.find(
        { 'gradlew', '.git', 'mvnw', 'build.gradle', 'build.gradle.kts' },
        { upward = true }
      )[1])
      require('jdtls').start_or_attach({
        cmd = { 'jdtls', '-data', workspace },
        root_dir = root,
      })
    end,
  },
}
