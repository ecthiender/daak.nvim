local M = {
	curr_idx = 1,
	inner = {},
}

-- Constructor
M.new = function(self, opts)
	local obj = {
		curr_idx = 1,
		inner = opts.inner or {},
	}
	-- Set InputStream as metatable to inherit methods
	setmetatable(obj, { __index = self })
	return obj
end

-- get item at current index
M.get = function(self)
	return self.inner[self.curr_idx]
end

-- forward the cursor and return item
M.next = function(self)
	local new_idx = self.curr_idx + 1
	if new_idx > #self.inner then
		return nil
	else
		self.curr_idx = new_idx
		return self:get()
	end
end

-- skip items (modify the internal cursor) for all empty strings, till a non-empty string is hit
M.skip_many_empty = function(self)
	while self.inner[self.curr_idx] == "" do
		self.curr_idx = self.curr_idx + 1
	end
end

return M
