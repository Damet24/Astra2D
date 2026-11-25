local utils = require("engine.graphics.utils")
local image = { getDimensions = function() return 32, 16 end }
love = {
	graphics = {
		newQuad = function(...) return { ... } end,
	},
}

local tileset = utils.loadQuads(image, 16, 16)
assert(tileset.image == image and #tileset.quads == 2)
assert(tileset.quads[1][1] == 0 and tileset.quads[2][1] == 16)
local animation = utils.loadAnimation(image, 16, 16, 0.1)
assert(animation.image == image and #animation.frames == 2 and animation.frameDuration == 0.1)
assert(animation.frames[1][1] == 0 and animation.frames[2][1] == 16)

local color = utils.rgba(255, 128, 0, 128)
assert(#color == 4)
assert(color[1] == 1 and color[3] == 0)
assert(math.abs(color[2] - 128 / 255) < 1e-12)
assert(math.abs(color[4] - 128 / 255) < 1e-12)
local opaque = utils.rgba(10, 20, 30)
assert(#opaque == 4 and opaque[4] == 1)
local ok, err = pcall(function() utils.rgba(256, 0, 0, 255) end)
assert(not ok and tostring(err):find("r must be a number between 0 and 255", 1, true))
print("graphics utils tests passed")