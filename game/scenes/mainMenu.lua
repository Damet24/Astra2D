local Scene = require("engine.scene.scene")
local GraphicsUtils = require("engine.graphics.utils")
local SpriteFont = require("engine.graphics.spriteFont")

local MainMenu = {}
MainMenu.__index = MainMenu
setmetatable(MainMenu, { __index = Scene })

function MainMenu.new(context)
    local self = Scene.new()

    setmetatable(self, MainMenu)

    self.context = context

    self.backgroundIndexAnimation = 0

    return self
end

function MainMenu:onLoad()
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

    self.context.audioManager:playMusic("music", { loop = true })

    self.backgroundImage = self.context.resourceManager:get(self, "background_purple")
end

function MainMenu:onEnter()
end

function MainMenu:update(dt)
    if self.context.inputManager:isJustPressed("accept") then
        self.context.sceneManager:replace("levels.level01")
    end

    self.backgroundIndexAnimation = (self.backgroundIndexAnimation + 4 * dt) % 64
end

function MainMenu:onDestroy()
    self.context.resourceManager:releaseAll(self)
end

local function drawStaticBackground(image, viewport, indexY)
	local screenWidth, screenHeight = viewport.getViewportDimensions()
	local tileW, tileH = 64, 64
    local offsetY = indexY % tileH

	for y = -tileH, screenHeight, tileH do
		for x = 0, screenWidth, tileW do
			love.graphics.draw(image, x, y + offsetY)
		end
	end
end

function MainMenu:draw()
    local width, height = self.context.viewport.getViewportDimensions()

    local text = "press enter to start"

    local textWidth = self.spriteFont:getWidth(text)
    local textHeight = self.spriteFont:getHeight(text)

    local x = (width - textWidth) / 2
    local y = (height - textHeight) / 2

    love.graphics.push("all")

    if self.backgroundImage then
		drawStaticBackground(self.backgroundImage, self.context.viewport, self.backgroundIndexAnimation)
	end

    self.spriteFont:draw(text, x, y)

    love.graphics.pop()
end

return MainMenu
