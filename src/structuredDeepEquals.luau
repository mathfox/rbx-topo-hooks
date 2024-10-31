--!strict
--!native
--!optimize 2

local function isArray(value: any): boolean
    if type(value) ~= "table" then
        return false
    end

    if next(value) == nil then
        -- an empty table is an empty array
        return true
    end

    -- We intentionally avoid using `rawlen` because we want structures like `Draft` to work.
    local length = #value

    if length == 0 then
        return false
    end

    local count = 0
    local sum = 0

    -- We intentionally use generalized iteration so that structures like `Draft` will work as intended.
    for key in value do
        if type(key) ~= "number" then
            return false
        end

        if key % 1 ~= 0 or key < 1 then
            return false
        end

        count += 1
        sum += key
    end

    return sum == (count * (count + 1) / 2)
end

local deepCompare: (left: unknown, right: unknown) -> boolean

-- Assumes that both values are checked with `isArray` function.
local function deepCompareArray(left: { unknown }, right: { unknown }): boolean
    if left == right then
        return true
    end

    local leftLength = #left

    if #right ~= leftLength then
        return false
    end

    for index = 1, leftLength do
        if not deepCompare(left[index], right[index]) then
            return false
        end
    end

    return true
end

local function deepCompareTable(left: { [unknown]: unknown }, right: { [unknown]: unknown }): boolean
    if left == right then
        return true
    end

    local leftKeysToValues: { [unknown]: unknown } = {}

    for key, value in left do
        if type(key) == "table" then
            leftKeysToValues[key] = value
        elseif not deepCompare(value, right[key]) then
            return false
        end
    end

    local rightKeysToValues: { [unknown]: unknown } = {}

    for key, value in right do
        if type(key) == "table" then
            rightKeysToValues[key] = value
        elseif not deepCompare(value, left[key]) then
            return false
        end
    end

    local clonedRightKeysToValues = table.clone(rightKeysToValues)

    for leftKey, leftValue in leftKeysToValues do
        local isMatchFound = false

        for rightKey, rightValue in clonedRightKeysToValues do
            if deepCompare(leftKey, rightKey) and deepCompare(leftValue, rightValue) then
                clonedRightKeysToValues[rightKey] = nil

                isMatchFound = true
                break
            end
        end

        if not isMatchFound then
            return false
        end
    end

    local clonedLeftKeysToValues = table.clone(leftKeysToValues)

    for rightKey, rightValue in rightKeysToValues do
        local isMatchFound = false

        for leftKey, leftValue in clonedLeftKeysToValues do
            if deepCompare(rightKey, leftKey) and deepCompare(rightValue, leftValue) then
                clonedLeftKeysToValues[leftKey] = nil

                isMatchFound = true
                break
            end
        end

        if not isMatchFound then
            return false
        end
    end

    return true
end

function deepCompare(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return left == right
    end

    if left == right then
        return true
    end

    local leftIsArray = isArray(left)
    local rightIsArray = isArray(right)

    if leftIsArray then
        if not rightIsArray then
            return false
        end

        return deepCompareArray(left :: { unknown }, right :: { unknown })
    elseif rightIsArray then
        return false
    end

    -- Here we know that both "a" and "b" are not arrays, but some table shape.

    return deepCompareTable(left :: { [unknown]: unknown }, right :: { [unknown]: unknown })
end

local function structuredDeepEquals(...: unknown): boolean
    local firstValue = select(1, ...)

    if not isArray(firstValue) then
        return false
    end

    for index = 2, select("#", ...) do
        local value = select(index, ...)

        if not isArray(value) then
            return false
        end

        if not deepCompareArray(firstValue :: { unknown }, value) then
            return false
        end
    end

    return true
end

return structuredDeepEquals