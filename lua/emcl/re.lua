local Re = {}

Re.new = function(re)
  local self = setmetatable({}, {
    __call = function(self, str)
      local s, e = self.re:match_str(str)
      return s and str:sub(s + 1, e) or nil
    end,
  })
  self.re = vim.regex(re)
  return self
end

return Re
