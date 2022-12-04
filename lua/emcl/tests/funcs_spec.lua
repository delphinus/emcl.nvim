local utils = require "emcl.tests.utils"

--[[
  m => method
  b => before
  a => after
  r => register
  br => register (beforehand)
  u => undo history
  bu => undo history (beforehand)
  au => undo history (afterhand)
  h => command history
]]
for _, c in ipairs {
  { m = "ForwardWord", b = "|abc   def", a = "abc|   def" },
  { m = "ForwardWord", b = "a|bc   def", a = "abc|   def" },
  { m = "ForwardWord", b = "ab|c   def", a = "abc|   def" },
  { m = "ForwardWord", b = "abc|   def", a = "abc   def|" },
  { m = "ForwardWord", b = "abc  | def", a = "abc   def|" },
  { m = "ForwardWord", b = "abc   def|", a = "abc   def|" },
  { m = "BackwardWord", b = "|abc   def", a = "|abc   def", r = "" },
  { m = "BackwardWord", b = "a|bc   def", a = "|abc   def", r = "a" },
  { m = "BackwardWord", b = "abc|   def", a = "|abc   def", r = "abc" },
  { m = "BackwardWord", b = "abc  | def", a = "|abc   def", r = "abc  " },
  { m = "BackwardWord", b = "abc   |def", a = "|abc   def", r = "abc   " },
  { m = "BackwardWord", b = "abc   d|ef", a = "abc   |def", r = "d" },
  { m = "BackwardWord", b = "abc   def|", a = "abc   |def", r = "def" },
  { m = "DeleteChar", b = "|abc", a = "|bc", r = "a", u = true },
  { m = "DeleteChar", b = "a|bc", a = "a|c", r = "b", u = true },
  { m = "DeleteChar", b = "ab|c", a = "ab|", r = "c", u = true },
  { m = "DeleteChar", b = "abc|", a = "abc|", r = "" },
  { m = "BackwardDeleteChar", b = "|abc", a = "|abc", r = "" },
  { m = "BackwardDeleteChar", b = "a|bc", a = "|bc", r = "a", u = true },
  { m = "BackwardDeleteChar", b = "abc|", a = "ab|", r = "c", u = true },
  { m = "KillLine", b = "|abc", a = "|", r = "abc", u = true },
  { m = "KillLine", b = "a|bc", a = "a|", r = "bc", u = true },
  { m = "KillLine", b = "abc|", a = "abc|", r = "" },
  { m = "BackwardKillLine", b = "|abc", a = "|abc", r = "" },
  { m = "BackwardKillLine", b = "a|bc", a = "|bc", r = "a", u = true },
  { m = "BackwardKillLine", b = "abc|", a = "|", r = "abc", u = true },
  { m = "KillWord", b = "|abc   def", a = "|   def", r = "abc", u = true },
  { m = "KillWord", b = "a|bc   def", a = "a|   def", r = "bc", u = true },
  { m = "KillWord", b = "abc|   def", a = "abc|", r = "   def", u = true },
  { m = "KillWord", b = "abc |  def", a = "abc |", r = "  def", u = true },
  { m = "KillWord", b = "abc   def|", a = "abc   def|", r = "" },
  { m = "KillWord", b = "abc |", a = "abc |", r = "" },
  { m = "KillWord", b = "abc| ", a = "abc|", r = " ", u = true },
  { m = "DeleteBackwardsToWhiteSpace", b = "|", a = "|", r = "", u = true },
  { m = "DeleteBackwardsToWhiteSpace", b = "|abc", a = "|abc", r = "", u = true },
  { m = "DeleteBackwardsToWhiteSpace", b = "abc|", a = "|", r = "abc", u = true },
  { m = "DeleteBackwardsToWhiteSpace", b = "abc |", a = "|", r = "abc ", u = true },
  { m = "DeleteBackwardsToWhiteSpace", b = "abc def|", a = "abc |", r = "def", u = true },
  { m = "DeleteBackwardsToWhiteSpace", b = "abc def |", a = "abc |", r = "def ", u = true },
  { m = "DeleteBackwardsToWhiteSpace", b = "abc de|f", a = "abc |f", r = "de", u = true },
  { m = "BackwardKillWord", b = "abc|", a = "|", r = "abc", u = true },
  { m = "BackwardKillWord", b = "abc,|", a = "|", r = "abc,", u = true },
  { m = "BackwardKillWord", b = "abc,def|", a = "abc,|", r = "def", u = true },
  { m = "BackwardKillWord", b = "abc,def,|", a = "abc,|", r = "def,", u = true },
  { m = "BackwardKillWord", b = "abc,de|f", a = "abc,|f", r = "de", u = true },
  { m = "TransposeChar", b = "ab|c", a = "acb|", r = "", u = true },
  { m = "TransposeChar", b = "|abc", a = "|abc", r = "" },
  { m = "TransposeChar", b = "a|", a = "a|", r = "" },
  { m = "TransposeChar", b = "abc|", a = "acb|", r = "", u = true },
  --[[
  { m = "TransposeWord", b = "|abc", a = "|abc", r = "" },
  { m = "TransposeWord", b = "abc |", a = "|abc ", r = "", u = true },
  { m = "TransposeWord", b = "| abc", a = " |abc", r = "", u = true },
  { m = "TransposeWord", b = "|abc efg", a = "efg abc|", r = "", u = true },
  { m = "TransposeWord", b = "a|bc efg", a = "efg abc|", r = "", u = true },
  { m = "TransposeWord", b = "ab|c efg", a = "efg abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc| efg", a = "efg abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc |efg", a = "efg abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc e|fg", a = "abc |efg", r = "", u = true },
  { m = "TransposeWord", b = "|abc ;; efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "a|bc ;; efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "ab|c ;; efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc| ;; efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc |;; efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc ;|; efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc ;;| efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc ;; |efg", a = "efg ;; abc|", r = "", u = true },
  { m = "TransposeWord", b = "abc ;; e|fg", a = "abc ;; |efg", r = "", u = true },
  ]]
  { m = "Yank", b = "|", a = "abc|", br = "abc", r = "abc", u = true },
  { m = "ToggleExternalCommand", b = "|", a = "!|", r = "", u = true },
  { m = "ToggleExternalCommand", b = "|!", a = "|", r = "", u = true },
  { m = "ToggleExternalCommand", b = "!|", a = "|", r = "", u = true },
  { m = "ToggleExternalCommand", b = "|abc", a = "!|abc", r = "", u = true },
  { m = "ToggleExternalCommand", b = "|!abc", a = "|abc", r = "", u = true },
  { m = "ToggleExternalCommand", b = "!|abc", a = "|abc", r = "", u = true },
  { m = "Undo", b = "|", a = "|", bu = {}, au = {} },
  { m = "Undo", b = "|", a = "abc|", bu = { "abc|", "|" }, au = { "|" } },
  { m = "YankLastArg", b = "a |b", a = "a abc|b", r = "", u = true, h = { "hoge abc" } },
  { m = "YankLastArg", b = "a |b", a = "a 'ab c'|b", r = "", u = true, h = { "hoge 'ab c'" } },
  { m = "YankLastArg", b = "a |b", a = "a 'ab c'|b", r = "", u = true, h = { "hoge({'ab c'})" } },
  { m = "YankLastArg", b = "a |b", a = "a 'ab''c'|b", r = "", u = true, h = { "hoge 'ab''c'" } },
  { m = "YankLastArg", b = "a |b", a = [[a "ab\"c"|b]], r = "", u = true, h = { [[hoge "ab\"c"]] } },
} do
  describe(c.m, function()
    it(("%s => %s%s"):format(c.b, c.a, c.h and ", h = " .. vim.inspect(c.h) or ""), function()
      local funcs = require("emcl.funcs").new()
      if c.br then
        funcs.register = c.br
      end
      if c.bu then
        funcs.old_cmdline = utils.convert_history(c.bu)
      end
      if c.h then
        utils.set_hist(c.h)
      end
      utils.set_linepos(c.b)
      funcs[c.m](funcs)
      assert.are.same(utils.expand_linepos(c.a), utils.get_linepos())
      if c.r then
        assert.are.same(c.r, funcs.register)
      end
      if c.u then
        local h = c.a == c.b and { c.a } or { c.a, c.b }
        assert.are.same(utils.convert_history(h), funcs.old_cmdline)
      end
      if c.bu then
        assert.are.same(utils.convert_history(c.au), funcs.old_cmdline)
      end
    end)
  end)
end
