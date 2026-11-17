local Scene = require("engine.scene.scene")
local {{sceneName}} = {}
{{sceneName}}.__index = {{sceneName}}
setmetatable({{sceneName}}, { __index = Scene })

function {{sceneName}}.new(context)
    local self = setmetatable(Scene.new(), {{sceneName}})
    self.context = context
    return self
end

function {{sceneName}}:update(dt)
end

function {{sceneName}}:draw()
end

return {{sceneName}}
