local M = {}

local remote = "fcitx5-remote"
local configured = false
local preferred_active = false

local function available()
	return vim.fn.executable(remote) == 1
end

---@return boolean|nil
local function input_method_active()
	if not available() then
		return nil
	end

	local output = vim.fn.system({ remote })
	if vim.v.shell_error ~= 0 then
		return nil
	end

	local state = tonumber(vim.trim(output))
	if not state then
		return nil
	end

	-- 0: closed, 1: inactive, 2: active
	return state == 2
end

---@param active boolean
local function set_input_method_active(active)
	if available() then
		vim.fn.system({ remote, active and "-o" or "-c" })
	end
end

function M.setup()
	if configured or not available() then
		return
	end
	configured = true

	local group = vim.api.nvim_create_augroup("UserFcitxMode", { clear = true })

	-- Start in Normal mode even when Neovim was launched with Chinese active.
	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		callback = function()
			local active = input_method_active()
			if active ~= nil then
				preferred_active = active
			end
			set_input_method_active(false)
		end,
	})

	-- Restore the Insert-mode preference, which may be English or Chinese.
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = function()
			set_input_method_active(preferred_active)
		end,
	})

	-- Remember the user's last Insert-mode choice before forcing normal mode.
	vim.api.nvim_create_autocmd("InsertLeavePre", {
		group = group,
		callback = function()
			local active = input_method_active()
			if active ~= nil then
				preferred_active = active
			end
			set_input_method_active(false)
		end,
	})

	-- Do not leave Fcitx disabled after Neovim exits.
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			if preferred_active then
				set_input_method_active(true)
			end
		end,
	})
end

return M
