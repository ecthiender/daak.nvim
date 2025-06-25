local M = {}

-- Simple, sane standard library utility functions. Mostly related to strings and arrays.

-- filter over an array with a predicate function
function M.filter(tbl, predicate)
	local result = {}
	for _, v in ipairs(tbl) do
		if predicate(v) then
			table.insert(result, v)
		end
	end
	return result
end

-- filter empty strings out from an array of strings
function M.filter_whitespace(lines)
	return M.filter(lines, function(s)
		return s ~= ""
	end)
end

-- filter string with a separator
function M.split(inputstr, sep)
	if sep == nil then
		sep = "%s" -- default to whitespace
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

-- trim a string off leading and trailing whitespaces;
-- it doesn't remove in whitespaces inside the string.
function M.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- trim array; delete leading and trailing empty strings
function M.trim_empty_strings(arr)
	local start_idx = 1
	local end_idx = #arr

	-- Find first non-empty string from the start
	while start_idx <= end_idx and arr[start_idx] == "" do
		start_idx = start_idx + 1
	end

	-- Find first non-empty string from the end
	while end_idx >= start_idx and arr[end_idx] == "" do
		end_idx = end_idx - 1
	end

	-- If all are empty, return empty table
	if start_idx > end_idx then
		return {}
	end

	-- Copy the trimmed range into a new table
	local result = {}
	for i = start_idx, end_idx do
		result[#result + 1] = arr[i]
	end

	return result
end

--- Neovim editor/UI related helpers
---
function M.notify(msg, level)
	vim.notify("[daak.nvim]: " .. msg, level)
end

-- Set keymap for current buffer only
function M.set_keymap_buffer_local(mode, lhs, rhs)
	vim.keymap.set(mode, lhs, rhs, { buffer = true })
end

return M
