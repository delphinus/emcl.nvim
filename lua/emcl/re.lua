---@alias emcl.re.Re fun(str: string): string?

local Re = {}

---@param re string
---@return emcl.re.Re
Re.new = function(re)
  return setmetatable({ re = vim.regex(re) }, {
    __call = function(self, str)
      local s, e = self.re:match_str(str)
      return s and str:sub(s + 1, e) or nil
    end,
  }) --[[@as emcl.re.Re]]
end

return Re
