local utils = require("daak.utils")
local stream = require("daak.stream")

local M = {}

-- The first-pass, simple naive parser.
-- Which just groups texts objects based on the `SEP`.
-- And marks their start and end line numbers.

SEP = "---"

-- f :: [String] -> [Int]
-- Takes a list of strings (lines), and returns a list of numbers.
-- Each number indicating the index in the original lines where `SEP` was found
local function parse_for_separator(lines)
	local parsed = {}
	for idx, line in ipairs(lines) do
		if line == SEP then
			table.insert(parsed, idx)
		end
	end
	return parsed
end

-- { 1, 3, 6, 11 } -> { {start = 1, fin = 3}, {start = 3, fin = 6}, {start = 6, fin = 11 } }
local function group_objects(parsed)
	local grouped = {}
	for idx, linenum in ipairs(parsed) do
		local next_idx = idx + 1
		if next_idx > #parsed then
			break
		end
		table.insert(grouped, {
			start = linenum,
			fin = parsed[next_idx],
		})
	end
	return grouped
end

local function test_group_objects()
	local foo = { 1, 5, 8, 16, 28 }
	local expected = {
		{ start = 1, fin = 5 },
		{ start = 5, fin = 8 },
		{ start = 8, fin = 16 },
		{ start = 16, fin = 28 },
	}
	local res = group_objects(foo)
	-- assert_eq(res, expected)
end

function M.find_group(grouped, line_num)
	for idx, object in ipairs(grouped) do
		if line_num >= object.start and line_num < object.fin then
			return idx
		end
	end
end

-- parses the text groups in the document.
-- A text group is anything separated the by `SEP` separator.
function M.parse_text_group(lines)
	local parsed = parse_for_separator(lines)
	local grouped = group_objects(parsed)
	return grouped
end

--- The second pass of the parser; which parses HTTP request
--- This parser itself has two phases.
--- The first phase, is where it tries to find 3 groups of text objects separated by optional whitespaces.
--- In these group of text objects, 1 group is mandatory, the other 2 are optional.
--- In the second phase, these 3 groups of text objects are taken, and then parsing of actual
--- HTTP request parts are made. The first text object is parsed as HTTP method (GET, POST etc.) and URL;
--- the second text object is parsed as headers, and the third text object is parsed as body.

local function parse_split_parts_response(lines)
	local s = stream:new({ inner = lines })
	-- Step 1: first line has to status
	local status = s:next()
	-- Step 2: can be any number of headers
	--
	-- if line == "" or line == "\r" or line == "\n" or line == "\r\n" then
	-- TODO: finish this..
end

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
		local header_value = utils.trim(parts[2])
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

return M
