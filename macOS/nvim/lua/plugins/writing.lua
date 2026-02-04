return {
  ---------------------------------------------------------------------------
  -- Markdown 渲染与预览
  ---------------------------------------------------------------------------
  -- 在 Neovim 内渲染 Markdown（标题、列表、表格、数学等）
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {}, -- 默认即可，后续按需微调
  },
  -- 浏览器实时预览（需要本机 Node）
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

  ---------------------------------------------------------------------------
  -- 中英文混排与表格
  ---------------------------------------------------------------------------
  -- 盘古之白：中文排版空格/标点轻度规范（保存时修正）
  { "hotoo/pangu.vim", ft = { "markdown", "text" } },
  -- Markdown 表格编辑辅助
  { "dhruvasagar/vim-table-mode", ft = { "markdown", "text" } },

  ---------------------------------------------------------------------------
  -- LSP：拼写/语法与 Markdown 语言服务
  ---------------------------------------------------------------------------
  -- Mason 保证工具安装到位
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "marksman", "ltex" })
    end,
  },
  -- LSP 具体配置：ltex 做英文语法/拼写，marksman 做 Markdown 结构
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ltex = { settings = { ltex = { language = "en-US" } } },
        marksman = {},
      },
    },
  },

  ---------------------------------------------------------------------------
  -- 格式化 & Lint（沿用 LazyVim 的 conform / nvim-lint 方式）
  ---------------------------------------------------------------------------
  -- Conform：给 Markdown 串上 autocorrect -> prettier(d)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      -- 先跑 CJK 文案规整，再交给 Prettier/Prettierd
      opts.formatters_by_ft.markdown = { "autocorrect", "prettierd", "prettier" }
    end,
  },
  -- nvim-lint：打开 markdownlint（可用 ~/.markdownlint.yaml 自定义规则）
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = { "markdownlint" } -- 或 "markdownlint-cli2"
    end,
  },

  ---------------------------------------------------------------------------
  -- 习惯项：Markdown 打开即适合“写”
  ---------------------------------------------------------------------------
  {
    "LazyVim/LazyVim",
    opts = {
      -- LazyVim 已内置 zen（Snacks.zen），快捷键 <leader>uz
      -- 这里只做文件类型优化
    },
    init = function()
      -- 写 Markdown/纯文本时更适合排版与校对
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "text" },
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.conceallevel = 2
          vim.opt_local.spell = true -- 英文拼写交给 ltex 更强
          vim.opt_local.spelllang = "en_us" -- 中文不走内置拼写
        end,
      })
    end,
  },
}
