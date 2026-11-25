-- Helpers for building ResourceManager definition tables.
local Utils = {}

local function add(definitions, id, definition)
    assert(not definitions[id], "duplicate resource id: " .. id)
    definitions[id] = definition
end

function Utils.addImages(definitions, root, directory, images)
    local prefix = root .. directory
    for id, filename in pairs(images) do
        add(definitions, id, { type = "image", path = prefix .. filename })
    end
end

function Utils.addSound(definitions, root, directory, sounds, soundType)
    local prefix = root .. directory
    for id, filename in pairs(sounds) do
        add(definitions, id, { type = "sound", path = prefix .. filename, soundType = soundType })
    end
end

return Utils
