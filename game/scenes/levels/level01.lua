local Level = require("game.scenes.levels.level")
local map = require("game.maps.village")

local Level01 = {}

function Level01.new(context)
	return Level.new(context, {
        map = map,
		background ="background_blue"
	})
end

return Level01
