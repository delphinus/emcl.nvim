local fn = vim.fn

local Funcs = require "emcl.funcs"
local Main = {}

Main.new = function()
  local self = setmetatable({}, { __index = Main })

  self.definitions = {
    ForwardChar = "<Right>",
    BackwardChar = "<Left>",
    BeginningOfLine = "<Home>",
    EndOfLine = "<End>",
    OlderMatchingCommandLine = "<Up>",
    NewerMatchingCommandLine = "<Down>",
    FirstLineInHistory = "<C-f>gg<C-c>",
    LastLineInHistory = "<C-f>Gk<C-c>",
    SearchCommandLine = "<C-f>?",
    AbortCommand = "<C-c>",
  }

  self.default_config = {
    enabled = "all",
    mappings = {
      ForwardChar = "<C-f>",
      BackwardChar = "<C-b>",
      BeginningOfLine = "<C-a>",
      EndOfLine = "<C-e>",
      OlderMatchingCommandLine = "<C-p>",
      NewerMatchingCommandLine = "<C-n>",
      FirstLineInHistory = "<M-<>",
      LastLineInHistory = "<M->>",
      SearchCommandLine = "<C-r>",
      AbortCommand = "<C-g>",

      ForwardWord = "<M-f>",
      BackwardWord = "<M-b>",
      DeleteChar = { "<Del>", "<C-d>" },
      BackwardDeleteChar = { "<BS>", "<C-h>" },
      KillLine = "<C-k>",
      BackwardKillLine = "<C-u>",
      KillWord = "<M-d>",
      DeleteBackwardsToWhiteSpace = "<C-w>",
      BackwardKillWord = "<M-BS>",
      TransposeChar = "<C-t>",
      TransposeWord = "<M-t>",
      Yank = "<C-y>",
      Undo = { "<C-_>", "<C-x><C-u>" },
      YankLastArg = { "<M-.>", "<M-_>" },
      ToggleExternalCommand = "<C-z>",
    },
    no_map_at_end = { "ForwardChar", "EndOfLine", "DeleteChar", "KillLine" },
    only_when_empty = { "SearchCommandLine" },
    old_map_prefix = "<C-o>",
    word_char_character_class = "a-zA-Z0-9_À-ÖØ-öø-ÿ",
    max_undo_history = 100,
  }
  self.config = {}
  return self
end

function Main:setup(config)
  local merged = vim.tbl_deep_extend("force", self.default_config, config or {})
  vim.validate {
    enabled = { merged.enabled, self:_all_or_valid_mappings(), 'string "all" or table containing mapping names' },
    mappings = { merged.mappings, self:_valid_mappings(), "valid table for mappings" },
    no_map_at_end = {
      merged.no_map_at_end,
      self:_valid_mapping_keys(),
      "table containing mapping names",
    },
    only_when_empty = {
      merged.only_when_empty,
      self:_valid_mapping_keys(),
      "table containing mapping names",
    },
  }
  self.config = merged
  self.funcs = Funcs.new(merged)
  self:set_mappings()
end

function Main:set_mappings()
  local mappings = {}
  if self.config.enabled == "all" then
    mappings = self.config.mappings
  else
    for _, v in ipairs(self.config.enabled) do
      mappings[v] = self.config.mappings[v]
    end
  end

  local function to_map(list)
    local map = {}
    for _, v in ipairs(list) do
      map[v] = true
    end
    return map
  end

  local no_map_at_end = to_map(self.config.no_map_at_end)
  local only_when_empty = to_map(self.config.only_when_empty)

  for name, v in pairs(mappings) do
    if type(v) == "string" then
      v = { v }
    end
    for _, key in ipairs(v) do
      vim.keymap.set("c", key, function()
        local expr = self.definitions[name]
        if no_map_at_end[name] then
          if fn.getcmdpos() > #fn.getcmdline() then
            expr = key
          end
        elseif only_when_empty[name] then
          if fn.getcmdline() ~= "" then
            expr = key
          end
        end
        if expr then
          return expr
        end
        require "emcl"(name)
      end, { expr = true })

      if self.config.old_map_prefix ~= "" then
        local old_map = self.config.old_map_prefix .. key
        if fn.maparg(old_map, "c") == "" then
          vim.keymap.set("c", old_map, key)
        end
      end
    end
  end
end

function Main:method(name)
  return function()
    return self.funcs[name](self.funcs)
  end
end

function Main:_all_or_valid_mappings()
  return function(v)
    if type(v) == "string" then
      return v == "all"
    elseif type(v) == "table" then
      return self:_valid_mapping_keys()(v)
    end
    return false
  end
end

function Main:_valid_mapping_keys()
  return function(v)
    if type(v) ~= "table" then
      return false
    end
    local i = 0
    for _ in pairs(v) do
      i = i + 1
      if not v[i] or not self.default_config.mappings[v[i]] then
        return false
      end
    end
    return true
  end
end

function Main:_valid_mappings()
  return function(v)
    if type(v) ~= "table" then
      return false
    end
    for k, definition in pairs(v) do
      if not self.default_config.mappings[k] then
        return false
      elseif type(definition) == "table" then
        for _, key in ipairs(definition) do
          if type(key) ~= "string" then
            return false
          end
        end
      elseif type(definition) ~= "string" then
        return false
      end
    end
    return true
  end
end

return Main.new()
