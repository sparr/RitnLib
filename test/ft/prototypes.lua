--- What the data-stage builders actually produced.
---
--- test/ft/rl-tests/data.lua plays the part of a consumer mod and drives the builder
--- classes; this checks the game ended up with what they claimed to build. This is the
--- half of RitnLib that RitnWaterfill depends on, and the half where 2.1's recipe change
--- (`category` and `additional_categories` merged into `categories`) could have bitten.

describe("builders that create prototypes outright", function()
    test.each({
        { "recipe_category", "rl-tests-category" },
        { "fuel_category", "rl-tests-fuel" },
        { "item_group", "rl-tests-group" },
        { "item_subgroup", "rl-tests-subgroup" },
    })("%s extend() produced %s", function(collection, name)
        assert.is_truthy(prototypes[collection][name],
            "the builder reported success but the game has no " .. collection .. " called " .. name)
    end)

    test("the subgroup landed in the group it was given", function()
        assert.equals("rl-tests-group", prototypes.item_subgroup["rl-tests-subgroup"].group.name)
    end)
end)

describe("builders that mutate an existing prototype", function()
    test("addIngredient added the ingredient", function()
        local found = false
        for _, ingredient in pairs(prototypes.recipe["iron-gear-wheel"].ingredients) do
            if ingredient.name == "copper-plate" then found = true end
        end
        assert.is_true(found, "copper-plate is not among iron-gear-wheel's ingredients")
    end)

    test("addIngredient left the original ingredients alone", function()
        local found = false
        for _, ingredient in pairs(prototypes.recipe["iron-gear-wheel"].ingredients) do
            if ingredient.name == "iron-plate" then found = true end
        end
        assert.is_true(found, "adding an ingredient dropped the ones already there")
    end)

    test("changeSubgroup moved the recipe", function()
        assert.equals("rl-tests-subgroup", prototypes.recipe["iron-gear-wheel"].subgroup.name)
    end)

    -- The 2.1 recipe change lands here: whatever these methods wrote back, the game had to
    -- accept it as a valid recipe. A recipe whose categories field survived as a 2.0-shaped
    -- `category` string would not have loaded at all.
    test("the mutated recipe is still a working recipe", function()
        local recipe = game.forces.player.recipes["iron-gear-wheel"]
        assert.is_truthy(recipe, "the recipe vanished from the force")

        -- 2.1 replaced LuaRecipePrototype::category with a categories array, so read
        -- whichever the running version offers rather than assuming either.
        local proto = prototypes.recipe["iron-gear-wheel"]
        local categories = {}
        local ok, plural = pcall(function() return proto.categories end)
        if ok and plural then
            for _, category in pairs(plural) do categories[#categories + 1] = category end
        else
            local ok2, singular = pcall(function() return proto.category end)
            if ok2 and singular then categories[1] = singular end
        end

        local found = false
        for _, category in pairs(categories) do
            if category == "crafting" then found = true end
        end
        assert.is_true(found,
            "the recipe is no longer in the crafting category after the library rewrote it; "
            .. "got: " .. table.concat(categories, ", "))
    end)

    test("setEnabled(false) reached the force", function()
        assert.is_false(game.forces.player.recipes["copper-cable"].enabled,
            "the recipe is still enabled, so setEnabled did not take")
    end)
end)

describe("technology builders", function()
    test("addPrerequisite added it", function()
        local found = false
        for name in pairs(prototypes.technology["logistics-2"].prerequisites) do
            if name == "steel-processing" then found = true end
        end
        assert.is_true(found, "steel-processing is not a prerequisite of logistics-2")
    end)

    test("addPack added the science pack", function()
        local found = false
        for _, ingredient in pairs(prototypes.technology["logistics-2"].research_unit_ingredients) do
            if ingredient.name == "logistic-science-pack" then found = true end
        end
        assert.is_true(found, "logistic-science-pack is not in the research unit")
    end)
end)

--- All four of these validated their argument by indexing `data.raw.tool`, which a vanilla
--- 2.1 load leaves nil: 2.1.7 made science packs plain items, and nothing in the base game
--- defines a tool prototype any more. Each one therefore raised "attempt to index field
--- 'tool' (a nil value)" at the data stage and stopped the load outright, so reaching these
--- assertions at all is most of what they check.
describe("science pack methods against a version with no tool prototypes", function()
    local function pack_names(technology)
        local names = {}
        for _, ingredient in pairs(prototypes.technology[technology].research_unit_ingredients) do
            names[ingredient.name] = ingredient.amount
        end
        return names
    end

    local function lab_inputs()
        return prototypes.entity["lab"].lab_inputs
    end

    local function index_of(list, value)
        for i, entry in pairs(list) do
            if entry == value then return i end
        end
        return nil
    end

    test("replacePack swapped the pack and kept the amount", function()
        local packs = pack_names("logistics-3")
        assert.is_nil(packs["chemical-science-pack"],
            "chemical-science-pack is still in logistics-3, so replacePack did not remove it")
        assert.equals(1, packs["military-science-pack"],
            "military-science-pack did not arrive in logistics-3 with the amount it replaced")
    end)

    test("replacePack left the other packs alone", function()
        local packs = pack_names("logistics-3")
        assert.equals(1, packs["automation-science-pack"])
        assert.equals(1, packs["production-science-pack"])
    end)

    test("addPackLab put the pack back at the index it was given", function()
        assert.equals(1, index_of(lab_inputs(), "space-science-pack"),
            "space-science-pack is not the lab's first input, so the remove/add round trip "
            .. "did not happen: got " .. table.concat(lab_inputs(), ", "))
    end)

    test("the remove/add round trip left exactly one copy", function()
        local count = 0
        for _, input in pairs(lab_inputs()) do
            if input == "space-science-pack" then count = count + 1 end
        end
        assert.equals(1, count, "the lab has " .. count .. " space-science-pack inputs")
    end)

    test("addPackLab ignores a pack that is no prototype at all", function()
        assert.is_nil(index_of(lab_inputs(), "rl-tests-no-such-pack"),
            "a name that is neither an item nor a tool was added to the lab anyway")
    end)

    test("science packs really are plain items here", function()
        -- The condition that broke the lookup. Either answer is a version the library
        -- supports, so this records which one the run is on rather than demanding one.
        local pack_type = prototypes.item["logistic-science-pack"].type
        assert.is_true(pack_type == "item" or pack_type == "tool",
            "science packs are neither items nor tools on this version: " .. tostring(pack_type))
    end)
end)
