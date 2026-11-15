local SpriteFont = {}
SpriteFont.__index = SpriteFont

function SpriteFont.new(config)
    assert(config.image, "image is required")
    assert(config.quads, "quads are required")
    assert(config.glyphs, "glyphs is required")

    local self = setmetatable({}, SpriteFont)

    self.image = config.image
    self.quads = config.quads
    self.glyphs = config.glyphs

    self.glyphWidth = config.glyphWidth or 8
    self.glyphHeight = config.glyphHeight or 8

    self.spacing = config.spacing or 0
    self.lineHeight = config.lineHeight or self.glyphHeight

    self.fallback = config.fallback
    self.uppercase = config.uppercase or false

    return self
end

function SpriteFont:_getGlyph(char)
    local key = self.uppercase and char:upper() or char

    local quadIndex = self.glyphs[key]

    if not quadIndex and self.fallback then
        quadIndex = self.glyphs[self.fallback]
    end

    return quadIndex and self.quads[quadIndex]
end

function SpriteFont:getWidth(text)
    local maxWidth = 0
    local currentWidth = 0

    for char in text:gmatch(".") do
        if char == "\n" then
            maxWidth = math.max(maxWidth, currentWidth)
            currentWidth = 0
        else
            currentWidth = currentWidth + self.glyphWidth + self.spacing
        end
    end

    maxWidth = math.max(maxWidth, currentWidth)

    if maxWidth > 0 then
        maxWidth = maxWidth - self.spacing
    end

    return maxWidth
end

function SpriteFont:getHeight(text)
    local lines = 1

    for _ in text:gmatch("\n") do
        lines = lines + 1
    end

    return lines * self.lineHeight
end

function SpriteFont:draw(text, x, y, scale)
    scale = scale or 1

    local cursorX = x
    local cursorY = y

    local advance = (self.glyphWidth + self.spacing) * scale

    for char in text:gmatch(".") do
        if char == "\n" then
            cursorX = x
            cursorY = cursorY + self.lineHeight * scale
        else
            local quad = self:_getGlyph(char)

            if quad then
                love.graphics.draw(
                    self.image,
                    quad,
                    cursorX,
                    cursorY,
                    0,
                    scale,
                    scale
                )
            end

            cursorX = cursorX + advance
        end
    end
end

return SpriteFont
