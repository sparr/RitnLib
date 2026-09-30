--- The helper functions, which consumer mods require by path out of ritnlib.defines.
---
--- The paths sit flat on ritnlib.defines (.table, .string, .json), which is what the
--- RitnLibDefines annotations in defines.lua declare.
---
--- Pure Lua, no game state. They are here rather than in a unit tier because the library
--- has no unit tier and these still have to run inside Factorio's Lua.
local tbl = require(ritnlib.defines.table)
local str = require(ritnlib.defines.string)
local json = require(ritnlib.defines.json)

describe("table helpers", function()
    test("isTable tells tables from everything else", function()
        assert.is_true(tbl.isTable({}))
        assert.is_false(tbl.isTable("no"))
        assert.is_false(tbl.isTable(nil))
    end)

    test("length counts hash keys, which #t does not", function()
        assert.equals(3, tbl.length({ a = 1, b = 2, c = 3 }))
        assert.equals(0, tbl.length({}))
    end)

    test("isEmpty and isNotEmpty disagree with each other", function()
        assert.is_true(tbl.isEmpty({}))
        assert.is_false(tbl.isNotEmpty({}))
        assert.is_false(tbl.isEmpty({ 1 }))
        assert.is_true(tbl.isNotEmpty({ 1 }))
    end)

    -- Note the miss value: -1, not nil. A consumer writing `if tbl.indexOf(t, v) then`
    -- gets a truthy answer for a value that is not there.
    test("indexOf returns the position, and -1 for a miss", function()
        assert.equals(2, tbl.indexOf({ "a", "b", "c" }, "b"))
        assert.equals(-1, tbl.indexOf({ "a" }, "z"))
    end)

    test("containsKey looks at keys, not values", function()
        assert.is_true(tbl.containsKey({ alpha = 1 }, "alpha"))
        assert.is_false(tbl.containsKey({ alpha = 1 }, 1))
    end)

    test("isPosition recognizes both position shapes", function()
        assert.is_true(tbl.isPosition({ x = 1, y = 2 }))
        assert.is_false(tbl.isPosition({ 1 }))
    end)

    test("removeByValue removes the value, not the index", function()
        local t = { "a", "b", "c" }
        tbl.removeByValue(t, "b")
        assert.equals(2, #t)
        assert.equals(-1, tbl.indexOf(t, "b"))
    end)
end)

describe("string helpers", function()
    test("isString tells strings from everything else", function()
        assert.is_true(str.isString("yes"))
        assert.is_false(str.isString(1))
        assert.is_false(str.isString(nil))
    end)

    test("isEmptyString treats nil and the empty string alike", function()
        assert.is_true(str.isEmptyString(""))
        assert.is_true(str.isEmptyString(nil))
        assert.is_false(str.isEmptyString("x"))
    end)

    test("startsWith matches a prefix", function()
        assert.is_true(str.startsWith("ritn-default-12", "ritn-"))
        assert.is_false(str.startsWith("ritn-default-12", "default"))
    end)

    test("defaultValue substitutes only when there is nothing there", function()
        assert.equals("fallback", str.defaultValue(nil, "fallback"))
        assert.equals("given", str.defaultValue("given", "fallback"))
    end)
end)

describe("json helpers", function()
    test("survive a round trip", function()
        local original = { name = "ritn", count = 3, nested = { true, false } }
        local decoded = json.decode(json.encode(original))
        assert.equals("ritn", decoded.name)
        assert.equals(3, decoded.count)
        assert.is_true(decoded.nested[1])
        assert.is_false(decoded.nested[2])
    end)
end)
