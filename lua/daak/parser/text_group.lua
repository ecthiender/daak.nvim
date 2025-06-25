-- The first-pass, simple naive parser.
-- Which just groups texts objects based on the `SEP`.
-- And marks their start and end line numbers.
local M = {}

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

return M
