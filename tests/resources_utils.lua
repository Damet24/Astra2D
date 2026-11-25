local Utils = require("engine.resources.utils")

local definitions = {}

Utils.addImages(definitions, "assets/images/", "characters/", {
	idle = "Idle.png",
	run = "Run.png",
})
assert(definitions.idle.type == "image")
assert(definitions.idle.path == "assets/images/characters/Idle.png")
assert(definitions.run.path == "assets/images/characters/Run.png")

Utils.addSound(definitions, "assets/sounds/", "", {
	jump = "jump.wav",
}, "static")
assert(definitions.jump.type == "sound")
assert(definitions.jump.path == "assets/sounds/jump.wav")
assert(definitions.jump.soundType == "static")

Utils.addSound(definitions, "assets/music/", "", {
	theme = "theme.mp3",
}, "stream")
assert(definitions.theme.path == "assets/music/theme.mp3")
assert(definitions.theme.soundType == "stream")

local success, message = pcall(function()
	Utils.addImages(definitions, "assets/images/", "characters/", {
		idle = "Other Idle.png",
	})
end)
assert(not success and type(message) == "string" and message:find("duplicate resource id: idle", 1, true))
assert(definitions.idle.path == "assets/images/characters/Idle.png")

local count = 0
for _ in pairs(definitions) do
	count = count + 1
end
assert(count == 4)

print("resources utils tests passed")
