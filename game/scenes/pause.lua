local Scene = require("engine.scene.scene")
local GraphicsUtils = require("engine.graphics.utils")
local SpriteFont = require("engine.graphics.spriteFont")

local Pause = {}
Pause.__index = Pause

setmetatable(Pause, {
	__index = Scene,
})

function Pause.new(context)
	local self = Scene.new()
	setmetatable(self, Pause)
	self.context = context
	self.drawBelow = true
	return self
end

function Pause:onLoad()
    local spriteFontSrc = GraphicsUtils.loadQuads(self.context.resourceManager:get(self, "menu_text_white"), 8, 10)

    self.spriteFont = SpriteFont.new({
        image = spriteFontSrc.image,
        quads = spriteFontSrc.quads,
        glyphs = GraphicsUtils.createGlyphMap({
            "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
            "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
            "u", "v", "w", "x", "y", "z", " ", " ", " ", " ",
            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
            ".", ",", ":", "?", "!", "(", ")", "+", "-",
        }),
        glyphWidth = 8,
        glyphHeight = 10,
        spacing = 0,
        lineHeight = 10,
        fallback = "?",
        uppercase = false
    })
end

function Pause:update(dt)
	if self.context.inputManager:isJustPressed("exit") then
		self.context.sceneManager:pop()
	end
end

function Pause:onDestroy()
	self.context.resourceManager:releaseAll(self)
end

function Pause:draw()
    local width, height = self.context.viewport.getViewportDimensions()
    local text = "pausa"

    local textWidth = self.spriteFont:getWidth(text)
    local textHeight = self.spriteFont:getHeight(text)

    local x = (width - textWidth) / 2
    local y = (height - textHeight) / 2
	love.graphics.push("all")
	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", 0, 0, width, height)
	love.graphics.setColor(1, 1, 1, 1)
	self.spriteFont:draw(text, x, y)
	love.graphics.pop()
end

return Pause
