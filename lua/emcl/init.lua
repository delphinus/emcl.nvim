local main = require "emcl.main"

return setmetatable({
  main = main,
  setup = function(config)
    main:setup(config)
  end,
}, {
  __call = function(_, name)
    return main:method(name)()
  end,
})
