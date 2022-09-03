local Emcl = require "emcl.main"
local emcl = Emcl.new()

return setmetatable({
  emcl = emcl,
  setup = function(config)
    emcl:setup(config)
  end,
}, {
  __call = function(_, name)
    return emcl:method(name)()
  end,
})
