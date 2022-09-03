local fn = vim.fn
local Funcs = require "emcl.funcs"

---@alias Mappings { [string]: string|string[] }

---@alias Definitions { [string]: string }

---@class emcl.main.Config
---@field enabled "all"|string[]
---@field mappings Mappings
---@field no_map_at_end string[]
---@field only_when_empty string[]
---@field old_map_prefix string
---@field word_char_character_class string
---@field max_undo_history integer

---@class emcl.main.Emcl
---@field definitions Definitions
---@field default_config emcl.main.Config
---@field config emcl.main.Config
local Emcl = {}

---@return emcl.main.Emcl
Emcl.new = function()
  return setmetatable({
    definitions = {
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
    },
    default_config = {
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
    },
    config = {},
  }, { __index = Emcl })
end

---@param config emcl.main.Config
---@return nil
function Emcl:setup(config)
  ---@type emcl.main.Config
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

---@return nil
function Emcl:set_mappings()
  local mappings = {}
  if self.config.enabled == "all" then
    mappings = self.config.mappings
  else
    ---@type Mappings
    mappings = vim.tbl_map(function(v)
      return self.config.mappings[v]
    end, self.config.enabled)
  end

  for name, v in pairs(mappings) do
    local definition = self.definitions[name] or ([[<C-\>ev:lua.require'emcl'(']] .. name .. "')<CR>")
    local keys = type(v) == "string" and { v } or v
    for _, key in ipairs(keys) do
      if vim.tbl_contains(self.config.no_map_at_end, name) then
        ---@return string
        vim.keymap.set("c", key, function()
          local str = fn.getcmdline()
          return fn.getcmdpos() > #str and key or definition
        end, { expr = true })
      elseif vim.tbl_contains(self.config.only_when_empty, name) then
        ---@return string
        vim.keymap.set("c", key, function()
          local str = fn.getcmdline()
          return #str > 0 and key or definition
        end, { expr = true })
      else
        vim.keymap.set("c", key, definition)
      end
      if self.config.old_map_prefix ~= "" then
        local old_map = self.config.old_map_prefix .. key
        if fn.maparg(old_map, "c") == "" then
          vim.keymap.set("c", old_map, key)
        end
      end
    end
  end
end

---@param name string
---@return fun(): fun(): string
function Emcl:method(name)
  ---@return fun(): string
  return function()
    return self.funcs[name](self.funcs)
  end
end

---@return fun(v: any): boolean
function Emcl:_all_or_valid_mappings()
  ---@param v any
  ---@return boolean
  return function(v)
    if type(v) == "string" then
      return v == "all"
    elseif type(v) == "table" then
      return self:_valid_mapping_keys()(v)
    end
    return false
  end
end

---@return fun(v: any): boolean
function Emcl:_valid_mapping_keys()
  ---@param v any
  ---@return boolean
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

---@return fun(v: any): boolean
function Emcl:_valid_mappings()
  ---@param v any
  ---@return boolean
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

return Emcl
