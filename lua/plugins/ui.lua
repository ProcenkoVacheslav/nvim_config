
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
      },
      
      -- ИНТЕГРАЦИЯ НАШЕГО СКРИПТА АВТОМАТИЗАЦИИ ДЛЯ C++
      event_handlers = {
        {
          event = "file_added",
          handler = function(filepath)
            local cpp_manager = require("core.cpp_manager")
            local correct_hpp, filename = cpp_manager.handle_file_creation(filepath)
            
            if correct_hpp then
              -- Избавляемся от ошибочного файла, который neo-tree успел кинуть в корень
              if vim.fn.filereadable(filepath) == 1 and filepath ~= correct_hpp then
                vim.fn.delete(filepath)
              end
              
              -- Мягкая задержка, чтобы дать Neo-tree завершить отрисовку
              vim.defer_fn(function()
                require("neo-tree.sources.manager").refresh("filesystem")
                vim.cmd("edit " .. vim.fn.fnameescape(correct_hpp))
                vim.notify("Успешно создана C++ пара для " .. filename, vim.log.levels.INFO)
              end, 100)
            end
          end,
        },
        {
          event = "file_deleted",
          handler = function(filepath)
            local cpp_manager = require("core.cpp_manager")
            cpp_manager.handle_file_deletion(filepath)
            
            -- Обновляем дерево интерфейса после фонового удаления парного файла
            vim.defer_fn(function()
              require("neo-tree.sources.manager").refresh("filesystem")
            end, 100)
          end,
        },
      },
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
