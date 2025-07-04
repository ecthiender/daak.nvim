local http = require("daak.http")
local parser = require("daak.parser")
local utils = require("daak.utils")

local M = {
	__result_buf = nil,
	__result_win = nil,
}

local function open_result_win(req, res)
	M.__result_buf = vim.api.nvim_create_buf(false, true)
	local buf_result = { "daak.nvim - the original postman." }
	table.insert(buf_result, "======================================================")
	table.insert(buf_result, "< " .. req.method .. " " .. req.url .. " >")
	table.insert(buf_result, "======================================================")
	table.insert(buf_result, "")
	table.insert(buf_result, "RESPONSE:")
	table.insert(buf_result, "")
	table.insert(buf_result, res.status)
	table.insert(buf_result, "")
	vim.list_extend(buf_result, res.headers)
	table.insert(buf_result, "")
	vim.list_extend(buf_result, res.response)

	vim.api.nvim_buf_set_lines(M.__result_buf, 0, -1, true, buf_result)
	local opts = {
		width = 80,
		split = "below",
		win = 0,
	}
	M.__result_win = vim.api.nvim_open_win(M.__result_buf, false, opts)
	vim.api.nvim_set_current_win(M.__result_win)

	-- setup 'q' to close the window
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(M.__result_win, false)
	end, { buffer = true })
end

--- Read the text under user's cursor, and if it matches daak.nvim's HTTP spec,
--- it is executed as a request, and its response displayed in a separate popup
---- window.
M.run_request_under_cursor = function()
	-- get user's current line
	local user_cur_line, _ = unpack(vim.api.nvim_win_get_cursor(0))
	-- get all lines of the current buffer
	local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	-- group buffer lines into text objects (parser first-pass)
	local grouped = parser.text_group.parse_text_group(buf_lines)
	-- find out which text object user's cursor is on
	local selected_idx = parser.text_group.find_group(grouped, user_cur_line)
	if selected_idx == nil then
		utils.notify("No request object found under cursor", vim.log.levels.WARN)
		return
	end
	local object = grouped[selected_idx]

	-- now we know which text object, let's try to parse this text as HTTP request..
	-- (parser second-pass)
	local raw_lines = { unpack(buf_lines, object.start + 1, object.fin - 1) }
	local req = parser.http.parse_http_req(raw_lines)
	if req == nil then
		utils.notify("Error parsing HTTP request", vim.log.levels.ERROR)
		return
	end

	-- if all good, execute the http request
	http.make_req(req, function(res)
		local response_parts = parser.http.parse_split_parts_response(res)
		open_result_win(req, response_parts)
	end)
end

M.setup = function()
	vim.keymap.set("n", "<leader>dr", M.run_request_under_cursor, {
		desc = "Run request under cursor",
	})
end

return M
