--- The contract consumer mods actually depend on.
---
--- RitnLib is a library, so its behavior is its public surface: the `ritnlib` global that
--- `defines.lua` installs, and the twelve classes `core/setup-classes.lua` registers into
--- `_G`. A consumer that requires the library gets exactly these names and nothing else,
--- so these fixtures are the closest thing the library has to user-visible behavior.
---
--- Worth knowing: `_G` is per-mod in Factorio. The classes are only global inside a mod
--- that has required the library itself. These fixtures run from RitnLib's own
--- control.lua, so they see them.

local CLASSES = {
    "RitnLibRecipe", "RitnLibTechnology", "RitnLibForce", "RitnLibSurface",
    "RitnLibPlayer", "RitnLibEntity", "RitnLibEvent", "RitnLibGui",
    "RitnLibInventory", "RitnLibGuiElement", "RitnLibStyle", "RitnLibInformatron",
}

describe("the classes the library registers", function()
    test.each(CLASSES)("%s is a global", function(name)
        assert.is_truthy(_G[name], name .. " is not registered; a consumer requiring "
            .. "RitnLib would get a nil where it expects a class")
        assert.equals("table", type(_G[name]))
    end)

    test("are all callable, so a consumer can construct them", function()
        local uncallable = {}
        for _, name in ipairs(CLASSES) do
            local meta = getmetatable(_G[name])
            if not (meta and meta.__call) then uncallable[#uncallable + 1] = name end
        end
        assert.equals(0, #uncallable,
            "not constructible: " .. table.concat(uncallable, ", "))
    end)
end)

describe("the ritnlib defines tree", function()
    test("exists", function()
        assert.equals("table", type(ritnlib), "defines.lua did not install the global")
        assert.equals("table", type(ritnlib.defines))
    end)

    -- Every one of these is a documented path a consumer requires by name. A missing
    -- branch is a silently broken require in somebody else's mod.
    test.each({
        "class.prototype.recipe",
        "class.prototype.technology",
        "class.prototype.category",
        "class.prototype.fuelCategory",
        "class.prototype.group",
        "class.prototype.subgroup",
        "class.luaClass.player",
        "class.luaClass.surface",
        "class.luaClass.force",
        "class.luaClass.entity",
        "class.ritnClass.inventory",
        "class.ritnClass.setting",
        "table",
        "string",
        "json",
        "other",
    })("ritnlib.defines.%s resolves to a require path", function(path)
        local node, walked = ritnlib.defines, "ritnlib.defines"
        for key in string.gmatch(path, "[^.]+") do
            walked = walked .. "." .. key
            assert.is_truthy(node, walked .. " has a nil parent")
            node = node[key]
        end
        assert.equals("string", type(node), walked .. " is not a require path")
        assert.is_truthy(#node > 0, walked .. " is empty")
    end)

    test("names the fonts the gui styles refer to", function()
        assert.equals("table", type(ritnlib.defines.names.font))
        assert.equals("ritn-default-12", ritnlib.defines.names.font.defaut12)
    end)
end)

describe("the remote interface", function()
    test("is registered under RitnLib", function()
        assert.is_truthy(remote.interfaces["RitnLib"],
            "core/interfaces.lua did not register; consumers calling into RitnLib get an error")
    end)
end)
