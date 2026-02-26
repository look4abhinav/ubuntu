-- [7] AUTO-COMMANDS
-- --------------------------------------------------------------------------

-- Auto-Save on Focus Lost or Buffer Leave
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
	pattern = "*",
	command = "silent! wall",
})

-- Auto-command: Rename Terminal Buffer & Clean UI
-- This handles ANY terminal opened, ensuring it looks clean
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term-setup", { clear = true }),
	callback = function()
		-- Hide line numbers in terminal
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false

		-- Fix the name: Rename buffer to "Terminal"
		-- pcall prevents errors if "Terminal" name is already taken
		pcall(vim.cmd.file, "Terminal")
	end,
})
