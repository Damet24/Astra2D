local function loadAnimation(image, frameWidth, frameHeight, frameDuration)
	local width, height = image:getDimensions()

	local frames = {}

	for y = 0, height - frameHeight, frameHeight do
		for x = 0, width - frameWidth, frameWidth do
			frames[#frames + 1] = love.graphics.newQuad(x, y, frameWidth, frameHeight, width, height)
		end
	end

	return {
		image = image,
		frames = frames,
		frameDuration = frameDuration,
	}
end

local function loadQuads(image, Width, Height)
    local width, height = image:getDimensions()

    local quads = {}

    for y = 0, height - Height, Height do
        for x = 0, width - Width, Width do
            quads[#quads + 1] = love.graphics.newQuad(x, y, Width, Height, width, height)
        end
    end

    return {
        image = image,
        quads = quads
    }
end

local function channel(value, name)
    assert(type(value) == "number" and value >= 0 and value <= 255,
        name .. " must be a number between 0 and 255")
    return value / 255
end

local function rgba(r, g, b, a)
    return {
        channel(r, "r"),
        channel(g, "g"),
        channel(b, "b"),
        channel(a == nil and 255 or a, "a"),
    }
end

local function hexToRgb(hex)
    assert(type(hex) == "string", "hex must be a string")
    hex = hex:gsub("^#", "")
    assert((#hex == 3 or #hex == 6 or #hex == 8) and hex:match("^[%da-fA-F]+$"),
        "hex must contain 3, 6, or 8 hexadecimal digits")

    if #hex == 3 then
        hex = hex:gsub("(.)", "%1%1")
    end

    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = #hex == 8 and tonumber(hex:sub(7, 8), 16) / 255 or 1

    return r, g, b, a
end

local function createGlyphMap(characters)
    local glyphs = {}

    for index, char in ipairs(characters) do
        glyphs[char] = index
    end

    return glyphs
end

return {
	loadAnimation = loadAnimation,
    loadQuads = loadQuads,
    rgba = rgba,
    hexToRgb = hexToRgb,
	createGlyphMap = createGlyphMap
}
