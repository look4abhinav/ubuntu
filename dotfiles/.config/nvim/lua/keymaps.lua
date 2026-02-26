-- [6] CUSTOM KEYBINDINGS
-- --------------------------------------------------------------------------

-- Format Current Buffer (<Space>f)
vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ async = false, lsp_fallback = true })
	print("Formatted!")
end, { desc = "Format current buffer" })

-- Quick Close Window (<Space>q)
vim.keymap.set("n", "<leader>q", vim.cmd.q, { desc = "Close current window" })

-- Close Current Buffer (Leader + x) - Normal Mode
vim.keymap.set("n", "<leader>x", ":bdelete!<CR>", { silent = true, desc = "Close Buffer" })

-- NvimTree Toggle (Leader + e)
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true, desc = "Toggle File Tree" })

-- Buffer Navigation (Tab and Shift+Tab)
vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { silent = true, desc = "Next Tab" })
vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { silent = true, desc = "Prev Tab" })

-- Run Python File (<Space>r)
vim.keymap.set("n", "<leader>r", function()
	vim.cmd("write")
	vim.cmd("botright 10split")
	vim.cmd("wincmd j")
	vim.cmd("term uv run " .. vim.fn.expand("%"))
	vim.cmd("startinsert")
end, { desc = "Run Python file with uv" })

-- ==========================================
-- TERMINAL CONFIGURATION (Toggle Logic)
-- ==========================================

local state = { buf = -1 }

local function toggle_terminal()
	if not vim.api.nvim_buf_is_valid(state.buf) then
		-- Clean up dead "Terminal" buffers
		for _, b in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_get_name(b):match("Terminal$") then
				vim.api.nvim_buf_delete(b, { force = true })
			end
		end

		-- Create new
		vim.cmd("botright 15split | terminal")
		state.buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_name(state.buf, "Terminal")
		vim.cmd("startinsert")
	else
		-- Toggle Visibility
		local win = vim.fn.bufwinid(state.buf)
		if win ~= -1 then
			vim.api.nvim_win_close(win, true)
		else
			vim.cmd("botright 15split")
			vim.api.nvim_win_set_buf(0, state.buf)
			vim.cmd("startinsert")
		end
	end
end

-- Terminal Bindings
vim.keymap.set("n", "<leader>t", toggle_terminal, { desc = "Toggle Terminal" })
vim.keymap.set("t", "<leader>t", function()
	vim.cmd("stopinsert")
	toggle_terminal()
end, { desc = "Toggle Terminal" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })
vim.keymap.set("t", "<leader>x", "<C-\\><C-n>:bdelete!<CR>", { silent = true, desc = "Kill Terminal" })
