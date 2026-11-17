local Scene = require("engine.scene.scene")

local {{sceneName}} = {}
{{sceneName}}.__index = {{sceneName}}
setmetatable({{sceneName}}, { __index = Scene })

function {{sceneName}}.new(context)
    local self = setmetatable(Scene.new(), {{sceneName}})
    self.context = context
    return self
end

-- Se llama una vez cuando la escena se carga.
function {{sceneName}}:onLoad()
end

-- Se llama cuando la escena se activa al entrar en la pila.
function {{sceneName}}:onEnter()
end

-- Se llama cuando la escena deja de estar activa (push, pop, replace o clear).
function {{sceneName}}:onExit()
end

-- Se llama cuando la escena se elimina permanentemente de la pila.
function {{sceneName}}:onDestroy()
end

function {{sceneName}}:update(dt)
end

function {{sceneName}}:draw()
end

return {{sceneName}}
