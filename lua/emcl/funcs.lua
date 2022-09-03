local fn = vim.fn
local Re = require "emcl.re"

---@class Cmdline
---@field line string
---@field pos integer

---@class emcl.funcs.Config
---@field word_char_character_class string
---@field max_undo_history integer

---@class Re
---@field spaces_and_word emcl.re.Re
---@field word_and_spaces emcl.re.Re
---@field word_and_others emcl.re.Re
---@field chars_and_others emcl.re.Re
---@field spaces_and_chars emcl.re.Re
---@field chars_and_spaces emcl.re.Re
---@field any_and_spaces emcl.re.Re
---@field spaces emcl.re.Re
---@field head_spaces emcl.re.Re
---@field back_spaces emcl.re.Re
---@field head_char emcl.re.Re
---@field back_char emcl.re.Re
---@field back_back_char emcl.re.Re
---@field last_arg emcl.re.Re

---@class emcl.funcs.Funcs
---@field register string
---@field old_cmdline Cmdline[]
---@field last_line string
---@field last_pos integer
---@field config emcl.funcs.Config
---@field re Re
local Funcs = {}

---@param config emcl.main.Config
---@return emcl.funcs.Funcs
Funcs.new = function(config)
  config = vim.tbl_extend("force", {
    word_char_character_class = "a-zA-Z0-9_À-ÖØ-öø-ÿ",
    max_undo_history = 100,
  }, config or {})
  return setmetatable({
    register = "",
    old_cmdline = {},
    last_line = "",
    last_pos = 0,
    config = config,
    re = {
      spaces_and_word = Re.new([[\v^\s*[]] .. config.word_char_character_class .. [[]+]]),
      word_and_spaces = Re.new([[\v[]] .. config.word_char_character_class .. [[]+\s*$]]),
      word_and_others = Re.new(
        [[\v[]] .. config.word_char_character_class .. [[]+[^]] .. config.word_char_character_class .. [[\s]*$]]
      ),
      chars_and_others = Re.new [[\v[[:alnum:]_]+[^[:alnum:]_]*$]],
      spaces_and_chars = Re.new [=[\v^\s*[^[:alnum:]_[:blank:]]+]=],
      chars_and_spaces = Re.new [=[\v[^[:alnum:]_[:blank:]]+\s*$]=],
      any_and_spaces = Re.new [[\v\S+\s*$]],
      spaces = Re.new [[\v^\s+$]],
      head_spaces = Re.new [[\v^\s+]],
      back_spaces = Re.new [[\v\s+$]],
      head_char = Re.new "^.",
      back_char = Re.new ".$",
      back_back_char = Re.new [[.\ze.$]],
      last_arg = Re.new [[\v("([^"]+|\\.)*"|'([^']+|'')*'|(\S+|\\\s){-})\ze[]\)}\s]*$]],
    },
  }, { __index = Funcs })
end

---@param save boolean?
---@return string, integer, string, string
function Funcs:get_line(save)
  local line = fn.getcmdline()
  local pos = fn.getcmdpos()
  if save then
    self:save_undo_history(line, pos)
  end
  local left = line:sub(1, pos - 1)
  local right = line:sub(pos)
  return line, pos, left, right
end

---@param line string
---@param pos integer
---@return nil
function Funcs:save_undo_history(line, pos)
  if #self.old_cmdline == 0 or line ~= self.old_cmdline[1].line then
    table.insert(self.old_cmdline, 1, { line = line, pos = pos })
  else
    self.old_cmdline[1].pos = pos
  end
  if #self.old_cmdline > self.config.max_undo_history then
    table.remove(self.old_cmdline)
  end
end

---@return string
function Funcs:ForwardWord()
  local line, pos, _, right = self:get_line()
  local m = self.re.spaces_and_word(right) or self.re.spaces_and_chars(right)
  if m then
    fn.setcmdpos(pos + #m)
  else
    fn.setcmdpos(#line + 1)
  end
  return line
end

---@return string
function Funcs:BackwardWord()
  local line, pos, left = self:get_line()
  local m = self.re.word_and_spaces(left) or self.re.chars_and_spaces(left)
  if m then
    self.register = m
    fn.setcmdpos(pos - #m)
  else
    fn.setcmdpos(1)
  end
  return line
end

---@return string
function Funcs:DeleteChar()
  local line, pos, left, right = self:get_line()
  if #line == pos - 1 then
    return line
  end
  self:save_undo_history(line, pos)
  local m = self.re.head_char(right)
  if m then
    self.register = m
  end
  local modified = left .. right:sub(#m + 1)
  self:save_undo_history(modified, pos)
  return modified
end

---@return string
function Funcs:BackwardDeleteChar()
  local line, pos, left, right = self:get_line()
  if pos == 1 then
    return line
  end
  self:save_undo_history(line, pos)
  local m = self.re.back_char(left)
  if m then
    self.register = m
  end
  local modified = left:sub(1, -(#m + 1)) .. right
  self:save_undo_history(modified, pos - #m)
  fn.setcmdpos(pos - #m)
  return modified
end

---@return string
function Funcs:KillLine()
  local line, pos, left, right = self:get_line()
  if #line == pos - 1 then
    return line
  end
  self:save_undo_history(line, pos)
  self.register = right
  self:save_undo_history(left, pos)
  return left
end

---@return string
function Funcs:BackwardKillLine()
  local line, pos, left, right = self:get_line()
  if pos == 1 then
    return line
  end
  self:save_undo_history(line, pos)
  self.register = left
  self:save_undo_history(right, 1)
  fn.setcmdpos(1)
  return right
end

---@return string
function Funcs:KillWord()
  local line, pos, left, right = self:get_line()
  local m = self.re.spaces_and_word(right) or self.re.spaces_and_chars(right) or self.re.spaces(right)
  if not m then
    return line
  end
  self:save_undo_history(line, pos)
  self.register = m
  local modified = left .. right:sub(#m + 1)
  self:save_undo_history(modified, pos)
  return modified
end

---@return string
function Funcs:DeleteBackwardsToWhiteSpace()
  local line, pos, left, right = self:get_line(true)
  local m = self.re.any_and_spaces(left)
  if m then
    self.register = m
    local modified = left:sub(1, -#m - 1) .. right
    local new_pos = pos - #m
    self:save_undo_history(modified, new_pos)
    fn.setcmdpos(new_pos)
    return modified
  end
  m = self.re.spaces(left)
  if m then
    self.register = m
    fn.setcmdpos(1)
    return right
  end
  return line
end

---@return string
function Funcs:BackwardKillWord()
  local line, pos, left, right = self:get_line(true)
  local m = self.re.word_and_others(left) or self.re.chars_and_others(left)
  if m then
    self.register = m
    local modified = left:sub(1, -#m - 1) .. right
    local new_pos = pos - #m
    self:save_undo_history(modified, new_pos)
    fn.setcmdpos(new_pos)
    return modified
  end
  m = self.re.spaces(left)
  if m then
    self.register = m
    fn.setcmdpos(1)
    return right
  end
  return line
end

---@return string
function Funcs:TransposeChar()
  local line, pos, left, right = self:get_line()
  if pos == 1 or #line == 1 then
    return line
  end
  self:save_undo_history(line, pos)
  if right == "" then
    local head = self.re.back_char(left)
    local back = self.re.back_back_char(left)
    local new_line = left:sub(1, -#head - #back - 1) .. head .. back
    self:save_undo_history(new_line, pos)
    return new_line
  end
  local head = self.re.head_char(right)
  local back = self.re.back_char(left)
  local new_left = left:sub(1, -#back - 1) .. head
  local new_right = back .. right:sub(#head + 1)
  local new_line = new_left .. new_right
  local new_pos = pos + #back
  self:save_undo_history(new_line, new_pos)
  fn.setcmdpos(new_pos)
  return new_line
end

---@return string
function Funcs:TransposeWord()
  local line, pos, left, right = self:get_line()
  local new_left
  local new_right
  local left_word
  local right_word
  local spaces
  local left_part = self.re.word_and_spaces(left) or self.re.word_and_spaces(left)
  local right_part = self.re.spaces_and_word(right) or self.re.spaces_and_word(right)
  if left_part and right_part then
    new_left = left:sub(1, -#left_part)
    new_right = right:sub(#right_part)
    local left_spaces = self.re.back_spaces(left_part)
    left_word = left_part:sub(1, -#left_spaces)
    local right_spaces = self.re.head_spaces(right_part)
    right_word = right_part:sub(#right_spaces)
    spaces = left_spaces .. right_spaces
  else
    return line
  end
  self:save_undo_history(line, pos)
  local new_line = new_left .. right_word .. spaces .. left_word .. new_right
  local new_pos = #(new_left .. right_word .. spaces)
  self:save_undo_history(new_line, new_pos)
  fn.setcmdpos(new_pos)
  return new_line
end

---@return string
function Funcs:Yank()
  local line, pos, left, right = self:get_line()
  if self.register == "" then
    return line
  end
  self:save_undo_history(line, pos)
  local new_line = left .. self.register .. right
  local new_pos = pos + #self.register
  self:save_undo_history(new_line, new_pos)
  fn.setcmdpos(new_pos)
  return new_line
end

---@return string
function Funcs:ToggleExternalCommand()
  local line, pos = self:get_line(true)
  local new_line
  local new_pos
  if line:sub(1, 1) == "!" then
    new_pos = pos > 1 and pos - 1 or pos
    new_line = line:sub(2)
  else
    new_pos = pos + 1
    new_line = "!" .. line
  end
  self:save_undo_history(new_line, new_pos)
  fn.setcmdpos(new_pos)
  return new_line
end

---@return string
function Funcs:Undo()
  local line = fn.getcmdline()
  if #self.old_cmdline == 0 then
    return line
  end
  if line == self.old_cmdline[1] then
    table.remove(self.old_cmdline, 0)
    if #self.old_cmdline == 0 then
      return line
    end
  end
  local new_line = self.old_cmdline[1].line
  fn.setcmdpos(self.old_cmdline[1].pos)
  table.remove(self.old_cmdline, 1)
  return new_line
end

---@return string
function Funcs:YankLastArg()
  local line, pos, left, right = self:get_line()
  local cmd_hist_no = fn.histnr "cmd"
  if cmd_hist_no == 0 then
    return line
  elseif line ~= self.last_line or pos ~= self.last_pos then
    self.last_pos = pos
    self.last_line = line
  else
    cmd_hist_no = cmd_hist_no - 1
  end
  local arg
  while cmd_hist_no > 0 do
    local hist = fn.histget("cmd", cmd_hist_no)
    arg = self.re.last_arg(hist)
    if arg ~= "" then
      break
    end
  end
  if not arg then
    return line
  end
  self:save_undo_history(line, pos)
  local new_line = left .. arg .. right
  local new_pos = pos + #arg
  fn.setcmdpos(new_pos)
  self:save_undo_history(new_line, new_pos)
  return new_line
end

return Funcs
