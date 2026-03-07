-- [0] PRE-SETUP & PROVIDERS
-- --------------------------------------------------------------------------
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

-- Set Leader Key (Space)
vim.g.mapleader = " "

-- [1] GENERAL SETTINGS
-- --------------------------------------------------------------------------
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.guicursor = "n-v-c-i:ver25"

-- [2] CLIPBOARD (OSC 52)
do
	local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
	if ok and osc52 then
		vim.g.clipboard = {
			name = "osc52",
			copy = {
				["+"] = osc52.copy("+"),
				["*"] = osc52.copy("*"),
			},
			paste = {
				["+"] = osc52.paste("+"),
				["*"] = osc52.paste("*"),
			},
		}
	end
end

-- Use system clipboard by default when available
vim.opt.clipboard = "unnamedplus"

-- [3] DIAGNOSTICS UI
-- --------------------------------------------------------------------------
vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
	signs = true,
	underline = true,
	update_in_insert = true,
	severity_sort = true,
})
