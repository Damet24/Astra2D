
local CollisionFilter = {}

local CATEGORY_COUNT = 16
local unpackValues = table.unpack or unpack

local function validateCategories(categories, name)
    assert(type(categories) == "table", name .. " must be a table")

    local result = {}
    local seen = {}

    for _, category in ipairs(categories) do
        assert(
            type(category) == "number"
                and category % 1 == 0
                and category >= 1
                and category <= CATEGORY_COUNT,
            name .. " categories must be integers between 1 and 16"
        )

        if not seen[category] then
            seen[category] = true
            result[#result + 1] = category
        end
    end

    return result, seen
end

function CollisionFilter.apply(fixture, collider)
    collider = collider or {}

    local layers = collider.layer or { 1 }
    local layerCategories = validateCategories(layers, "layer")

    assert(#layerCategories > 0, "layer must contain at least one category")

    fixture:setCategory(unpackValues(layerCategories))

    -- Without a mask, preserve Box2D's default behavior:
    -- the fixture can collide with every category.
    if collider.mask == nil then
        return
    end

    local maskCategories, allowed = validateCategories(collider.mask, "mask")
    local ignored = {}

    -- Box2D's mask represents categories to ignore.
    -- Astra2D's mask represents categories to accept.
    for category = 1, CATEGORY_COUNT do
        if not allowed[category] then
            ignored[#ignored + 1] = category
        end
    end

    fixture:setMask(unpackValues(ignored))
end

return CollisionFilter
