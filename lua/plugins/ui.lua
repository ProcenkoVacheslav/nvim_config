
return {
  { 
    "catppuccin/nvim", 
    name = "catppuccin", 
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin"
    end
  },

  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({})
    end
  },

  { "kdheepak/lazygit.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          always_show_bufferline = true,
          offsets = {
            {
              filetype = "neo-tree",
              text = "File Explorer",
              text_align = "center",
              separator = true,
            }
          },
        }
      })
    end,
  },

  
  
{
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      enable_git_status = true,
      enable_diagnostics = true,
      
      sources = { "filesystem", "buffers", "git_status" },
      source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          { source = "filesystem", display_name = "    Files " },
          { source = "buffers", display_name = "    Buffers " },
          { source = "git_status", display_name = "    Git " },
        },
      },
      filesystem = {
        use_libuv_file_watcher = true, 
        
        filtered_items = {
          visible = true,
        },
        follow_current_file = {
          enabled = false,
        },
      },
      window = {
        mappings = {
          ["L"] = "next_source",
          ["H"] = "prev_source",
        }
      }
    })
  end
},


  { 'famiu/bufdelete.nvim' },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "query", "python", "html", "css" },
        highlight = {
          enable = true, -- Включаем умную подсветку
        },
      })
    end,
  }
}
