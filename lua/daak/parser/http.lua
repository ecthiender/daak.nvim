local utils = require("daak.utils")
local stream = require("daak.stream")

local M = {}

--- The second pass of the parser; which parses HTTP request
--- This parser itself has two phases.
--- The first phase, is where it tries to find 3 groups of text objects separated by optional whitespaces.
--- In these group of text objects, 1 group is mandatory, the other 2 are optional.
--- In the second phase, these 3 groups of text objects are taken, and then parsing of actual
--- HTTP request parts are made. The first text object is parsed as HTTP method (GET, POST etc.) and URL;
--- the second text object is parsed as headers, and the third text object is parsed as body.

-- Parse and split into 3 parts based on variable whitespace
local function parse_split_parts(lines)
	local input = stream:new({ inner = lines })
	-- Step 1: skip zero or more empty
	input:skip_many_empty()

	-- Step 2: first non-empty line has to be the preamble
	local preamble = input:get()

	-- Step 3: Next, either stream is over, or we get empty lines
	if input:next() == nil then
		-- if next is nil, then our stream has finished..
		return { preamble = preamble }
	end
	-- Step 3.1: if stream is not over, skip empty lines
	input:skip_many_empty()

	-- Step 4: At next occurence of non-empty, try to parse headers
	local raw_headers = {}
	local curr_line = input:get()
	while curr_line ~= nil and curr_line ~= "" do
		table.insert(raw_headers, curr_line)
		curr_line = input:next()
	end

	-- Step 5: Next, either input is over, or we get empty lines
	if input:next() == nil then
		-- if next is nil, then our input has finished..
		return { preamble = preamble, raw_headers = raw_headers }
	end

	-- Step 6: At next occurence of non-empty till the end of input, assume as body
	local raw_body = {}
	local curr_line = input:get()
	while curr_line ~= nil and curr_line ~= "" do
		table.insert(raw_body, curr_line)
		curr_line = input:next()
	end
	return {
		preamble = preamble,
		raw_headers = raw_headers,
		raw_body = raw_body,
	}
end

local function is_http_method(word)
	return word == "GET" or word == "POST" or word == "PUT" or word == "DELETE" or word == "HEAD"
end

local function parse_preamble(line)
	local words = utils.split(line, " ") -- split by space
	if is_http_method(words[1]) then
		local method = words[1]
		local url = { unpack(words, 2, #words) }
		return { method = method, url = table.concat(url, " ") }
	end
end

local function parse_headers(lines)
	if lines == nil then
		return nil
	end
	local filtered = utils.trim_empty_strings(lines)
	if #filtered == 0 then
		return nil
	end

	local headers = {}
	for _, header in ipairs(filtered) do
		local parts = utils.split(header, ":")
		local header_name = utils.trim(parts[1])
		local rest_parts = { unpack(parts, 2, #parts) }
		local header_value = utils.trim(table.concat(rest_parts, ":"))
		headers[header_name] = header_value
	end
	return headers
end

local function parse_body(lines)
	if lines == nil then
		return nil
	end
	local filtered = utils.trim_empty_strings(lines)
	if #filtered == 0 then
		return nil
	end

	return table.concat(filtered, "\n")
end

local function parse_error(err)
	local msg = string.format("Error: Not a valid HTTP request under cursor. Parse Error: %s", err)
	utils.notify(msg, vim.log.levels.ERROR)
end

function M.parse_http_req(raw_lines)
	-- first-phase; split the lines into 3 expected parts,
	-- ignoring various configuration of newlines and whitespaces.
	local parts = parse_split_parts(raw_lines)

	-- second phase; parse actual HTTP request objects from parsed parts

	-- parse preamble
	local preamble = parse_preamble(parts.preamble)
	if preamble == nil then
		parse_error("Unable to find preamble.")
		return
	end

	-- parse headers
	local headers = parse_headers(parts.raw_headers)

	-- parse body
	local body = parse_body(parts.raw_body)

	return {
		method = preamble.method,
		url = preamble.url,
		headers = headers,
		body = body,
	}
end

function M.parse_split_parts_response(lines)
	vim.print(lines)
	local s = stream:new({ inner = lines })
	-- Step 1: first line has to status
	local status = s:get()
	if status == nil then
		vim.schedule(function()
			utils.notify("Parsing response failed. No status line", vim.log.levels.ERROR)
		end)
		return
	end
	print("Raw response status:")
	vim.print(status)

	-- Step 2: can be any number of headers
	local headers = {}
	while s:next() ~= "" do
		local line = s:get()
		table.insert(headers, line)
	end
	print("Raw response headers:")
	vim.print(headers)

	-- Step 3: response body if any
	local response = {}
	while s:next() ~= nil do
		local line = s:get()
		table.insert(response, line)
	end
	print("Raw response body:")
	vim.print(response)
	return {
		status = status,
		headers = headers,
		response = response,
	}
	-- if line == "" or line == "\r" or line == "\n" or line == "\r\n" then
	-- TODO: finish this..
end

return M
