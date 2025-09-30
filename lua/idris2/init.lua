local config = require("idris2.config")
local semantic = require("idris2.semantic")
local hover = require("idris2.hover")
local code_action = require("idris2.code_action")

local M = {}

local nvim_lsp = require("lspconfig")

local function setup_on_attach()
	local lsp_opts = config.options.server
	local old_on_attach = lsp_opts.on_attach -- Save user callback

	lsp_opts.on_attach = function(...)
		if config.options.autostart_semantic then
			semantic.request()
		end

		if old_on_attach ~= nil then
			old_on_attach(...) -- Call user callback
		end
	end
end

local function setup_capabilities()
	local lsp_opts = config.options.server
	local capabilities = vim.lsp.protocol.make_client_capabilities()

	capabilities["workspace"]["semanticTokens"] = { refreshSupport = true }
	capabilities["textDocument"]["hover"]["contentFormat"] = {}
	lsp_opts.capabilities = vim.tbl_deep_extend("force", capabilities, lsp_opts.capabilities or {})
end

local function setup_handlers()
	local lsp_opts = config.options.server
	local custom_handlers = {}

	custom_handlers["textDocument/semanticTokens/full"] = semantic.full
	custom_handlers["workspace/semanticTokens/refresh"] = semantic.refresh
	custom_handlers["textDocument/hover"] = hover.handler

	lsp_opts.handlers = vim.tbl_deep_extend("force", custom_handlers, lsp_opts.handlers or {})
end

local function setup_lsp()
	local root_dir_error = function(bufnr, on_dir)
		local startpath = vim.api.nvim_buf_get_name(bufnr)
		local path = nvim_lsp.util.root_pattern("*.ipkg")(startpath)
		if path == nil then
			vim.notify(
				string.format(
					"[idris2_lsp] could not find an .ipkg file in %s or any parent directory.\nHint: use 'idris2 --init' or 'pack new' to intialize an Idris2 project.",
					startpath
				),
				vim.log.levels.WARN
			)
		end
		on_dir(path)
	end
	local server = vim.tbl_deep_extend("force", config.options.server, { root_dir = root_dir_error })
	vim.lsp.config("idris2_lsp", server)
	vim.lsp.enable("idris2_lsp")
end

function M.setup(options)
	config.setup(options)

	setup_capabilities()
	setup_on_attach()
	setup_handlers()
	hover.setup()
	code_action.setup()

	if config.options.use_default_semantic_hl_groups then
		vim.cmd([[highlight link LspSemantic_variable idrisString]])
		vim.cmd([[highlight link LspSemantic_enumMember idrisStructure]])
		vim.cmd([[highlight link LspSemantic_function idrisIdentifier]])
		vim.cmd([[highlight link LspSemantic_type idrisType]])
		vim.cmd([[highlight link LspSemantic_keyword idrisStatement]])
		vim.cmd([[highlight link LspSemantic_namespace idrisImport]])
		vim.cmd([[highlight link LspSemantic_postulate idrisStatement]])
		vim.cmd([[highlight link LspSemantic_module idrisModule]])
	end

	setup_lsp()
end

function M.show_implicits()
	vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", { settings = { showImplicits = true } })
end

function M.hide_implicits()
	vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", { settings = { showImplicits = false } })
end

function M.show_machine_names()
	vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", { settings = { showMachineNames = true } })
end

function M.hide_machine_names()
	vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", { settings = { showMachineNames = false } })
end

function M.full_namespace()
	vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", { settings = { fullNamespace = true } })
end

function M.hide_namespace()
	vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", { settings = { fullNamespace = false } })
end

return M
