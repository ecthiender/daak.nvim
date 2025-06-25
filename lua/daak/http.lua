local utils = require("daak.utils")

local M = {}

local function make_curl(req)
	-- curl https://api.example.com/data
	local fmtstr = "curl -i %s -X %s "
	local s
	-- if we have request body, then append the body to the format string, otherwise skip it
	if req.body ~= nil then
		fmtstr = fmtstr .. " -d '%s' "
		s = string.format(fmtstr, req.url, req.method, req.body)
	else
		s = string.format(fmtstr, req.url, req.method)
	end
	return s
end

local function append_headers(req, str)
	local headers = req.headers or {}
	for name, val in pairs(headers) do
		local h = name .. ": " .. val
		str = str .. " -H '" .. h .. "' "
	end
	return str
end

function M.make_req(req, on_output)
	local cmd = make_curl(req)
	cmd = append_headers(req, cmd)

	-- Start async job
	local stdout = {}
	local stderr = {}

	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data, _)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stdout, line)
					end
				end
			end
		end,
		on_stderr = function(_, data, _)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stderr, line)
					end
				end
			end
		end,
		on_exit = function(_, exit_code, _)
			if exit_code == 0 then
				local output = table.concat(stdout, "\n")
				on_output(output)
			else
				local err_output = table.concat(stderr, "\n")
				vim.schedule(function()
					utils.notify("Request failed:\n" .. err_output, vim.log.levels.ERROR)
				end)
			end
		end,
	})

	if job_id <= 0 then
		utils.notify("Failed to start curl job", vim.log.levels.ERROR)
	else
		utils.notify("Request started...", vim.log.levels.INFO)
	end
end

local function run_async_cmd(cmd, on_output)
	local stdout = {}
	local stderr = {}

	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,

		on_stdout = function(_, data)
			if data then
				vim.list_extend(stdout, data)
			end
		end,

		on_stderr = function(_, data)
			if data then
				vim.list_extend(stderr, data)
			end
		end,

		on_exit = function(_, exit_code)
			if exit_code == 0 then
				on_output(table.concat(stdout, "\n"))
			else
				vim.notify("Error: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
			end
		end,
	})

	if job_id <= 0 then
		utils.notify("Failed to start cmd job", vim.log.levels.ERROR)
	else
		utils.notify("Request started...", vim.log.levels.INFO)
	end
end

return M
