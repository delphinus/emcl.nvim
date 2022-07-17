local cmdline = ""
local cmdpos = 0
local cmdhist = {}
vim.fn.getcmdline = function()
  return cmdline
end
vim.fn.getcmdpos = function()
  return cmdpos
end
vim.fn.setcmdpos = function(pos)
  cmdpos = pos
end
vim.fn.histnr = function(_)
  return #cmdhist
end
vim.fn.histget = function(_, num)
  return cmdhist[num]
end

local function expand_linepos(linepos)
  local pos = vim.regex("|"):match_str(linepos) + 1
  return { linepos:sub(1, pos - 1) .. linepos:sub(pos + 1), pos }
end

return {
  set_linepos = function(str)
    local left, right = str:match [[(.*)%|(.*)]]
    cmdline = left .. right
    cmdpos = #left + 1
  end,

  expand_linepos = expand_linepos,

  get_linepos = function()
    return { cmdline, cmdpos }
  end,

  set_line = function(str)
    cmdline = str
  end,

  set_hist = function(h)
    cmdhist = h
  end,

  convert_history = function(u)
    return vim.tbl_map(expand_linepos, u)
  end,
}
