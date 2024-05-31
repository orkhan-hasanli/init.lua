local function get_python_path()
    if vim.env.VIRTUAL_ENV then
        return vim.env.VIRTUAL_ENV .. '/bin/python'
    end

    local match = vim.fn.glob(vim.fn.getcwd() .. '/deployable/amplify/src/.venv39/bin/python')
    if match ~= '' then
        return match
    end
    return 'python'
end

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
    },

    config = function()
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "gopls",
                "ruff",
            },
            handlers = {
                function(server_name) -- default handler (optional)

                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,

                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = { version = "Lua 5.1" },
                                diagnostics = {
                                    globals = { "vim", "it", "describe", "before_each", "after_each" },
                                }
                            }
                        }
                    }
                end,

                ["ruff"] = function()
                    local lspconfig = require("lspconfig")
                    local att_dir = vim.env.ATT
                    lspconfig.ruff.setup({
                        capabilities = capabilities,
                        cmd = { get_python_path(), '-m', 'ruff'}
                    })
                end,

                ["pylsp"] = function()
                    local lspconfig = require("lspconfig")
                    local att_dir = vim.env.ATT
                    lspconfig.pylsp.setup({
                        capabilities = capabilities,
                        filetypes = {"python"},
                        settings = {
                            pylsp = {
                                plugins = {
                                    black = { enabled = true },
                                    autopep8 = { enabled = false },
                                    yapf = { enabled = false },
                                    -- linter options
                                    pylint = { enabled = false, executable = "pylint" },
                                    pyflakes = { enabled = false },
                                    pycodestyle = { enabled = false },
                                    -- type checker
                                    pylsp_mypy = {
                                        enabled = true,
                                        config_sub_paths = {att_dir .. "/build_tools/conf/"}
                                    },
                                    -- auto-completion options
                                    -- jedi_completion = { fuzzy = true },
                                    -- import sorting
                                    pyls_isort = { enabled = false },
                                }
                            }
                        },
                        cmd = { get_python_path(), '-m', 'pylsp'}
                    })
                end,

                -- ["pylsp"] = function()
                --     local lspconfig = require("lspconfig")
                --     local util = require("lspconfig.util")
                --
                --     local att_dir = vim.env.ATT
                --     local is_within_att = function(fname)
                --         return att_dir and fname:sub(1, #att_dir) == att_dir
                --     end
                --
                --     local settings = {}
                --     if is_within_att(vim.fn.getcwd()) then
                --         settings = {
                --             pylsp = {
                --                 configurationSources = { "flake8" },
                --                 plugins = {
                --                     flake8 = {
                --                         config = att_dir .. '/.flake8'
                --                     },
                --                     black = {
                --                         enabled = true,
                --                         line_length = 120,
                --                     },
                --                 },
                --             }
                --         }
                --     else
                --         settings = {
                --             pylsp = {
                --                 configurationSources = { "flake8" },
                --                 plugins = {
                --                     flake8 = {},
                --                     black = {
                --                         enabled = true,
                --                         line_length = 120,
                --                     },
                --                 },
                --             }
                --         }
                --     end
                --
                --     lspconfig.pylsp.setup {
                --         capabilities = capabilities,
                --         root_dir = function(fname)
                --             if is_within_att(fname) then
                --                 return util.root_pattern(unpack({
                --                     './build-tools/conf/mypy.ini',
                --                     './build-tools/setup.py',
                --                     './build-tools/setup.cfg',
                --                     './build-tools/requirements.txt',
                --                     './build-tools/dependencies.txt',
                --                 }))(fname) or util.find_git_ancestor(fname)
                --             else
                --                 return util.find_git_ancestor(fname)
                --             end
                --         end,
                --         settings = settings,
            --         }
            --     end,
            }
        })

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })

        vim.diagnostic.config({
            -- update_in_insert = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })
    end
}

