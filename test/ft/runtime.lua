--- The runtime wrappers, against real game objects.
---
--- These are the classes a consumer mod uses every tick, so what matters is that a real
--- LuaSurface, LuaForce or LuaEntity goes in and the documented fields come back out.

describe("RitnLibSurface", function()
    test("wraps a real surface and exposes its name and index", function()
        local wrapped = RitnLibSurface(game.surfaces["nauvis"])
        assert.equals("RitnLibSurface", wrapped.object_name)
        assert.equals("nauvis", wrapped.name)
        assert.equals(game.surfaces["nauvis"].index, wrapped.index)
        assert.is_true(wrapped.isNauvis, "nauvis was not recognized as nauvis")
        assert.is_true(wrapped.isPresent)
    end)

    -- The class takes a LuaSurface and nothing else. Handed anything else it logs
    -- "not LuaSurface !" and hands back an object whose fields are all nil, so a consumer
    -- that passes an index gets no error and no surface. isPresent is the only way to
    -- tell, which is why it is worth pinning.
    test("refuses a surface index, and says so through isPresent", function()
        local wrapped = RitnLibSurface(1)
        assert.is_falsy(wrapped.name, "a surface index is now accepted; the contract widened")
        assert.is_false(wrapped.isPresent,
            "a wrapper built from a bad argument claims to be present")
    end)
end)

describe("RitnLibForce", function()
    test("wraps a real force and exposes its name", function()
        local wrapped = RitnLibForce(game.forces["player"])
        assert.equals("RitnLibForce", wrapped.object_name)
        assert.equals("player", wrapped.name)
        assert.is_true(wrapped.isPresent)
    end)

    test("carries the force name constants consumers branch on", function()
        local wrapped = RitnLibForce(game.forces["player"])
        assert.equals("player", wrapped.FORCE_PLAYER_NAME)
        assert.equals("enemy", wrapped.FORCE_ENEMY_NAME)
        assert.equals("neutral", wrapped.FORCE_NEUTRAL_NAME)
    end)
end)

describe("RitnLibEntity", function()
    local surface, chest

    before_each(function()
        surface = game.surfaces["nauvis"]
        surface.request_to_generate_chunks({ 0, 0 }, 2)
        surface.force_generate_chunk_requests()
        for _, e in pairs(surface.find_entities_filtered { area = { { -8, -8 }, { 8, 8 } }, name = "wooden-chest" }) do
            e.destroy()
        end
        chest = surface.create_entity { name = "wooden-chest", position = { 3, 3 }, force = "player" }
    end)

    after_each(function() if chest and chest.valid then chest.destroy() end end)

    test("wraps a real entity and exposes name, type and position", function()
        local wrapped = RitnLibEntity(chest)
        assert.equals("RitnLibEntity", wrapped.object_name)
        assert.equals("wooden-chest", wrapped.name)
        assert.equals("container", wrapped.type)
        -- a 1x1 entity snaps to the middle of its tile, so this is 3.5 and not 3
        assert.equals(chest.position.x, wrapped.position.x)
        assert.equals(chest.position.y, wrapped.position.y)
        assert.is_true(wrapped.isPresent)
    end)

    test("knows a chest is not a character or a vehicle", function()
        local wrapped = RitnLibEntity(chest)
        assert.is_false(wrapped.isCharacter)
        assert.is_false(wrapped.isCar)
        assert.is_false(wrapped.isSpiderVehicle)
    end)

    test("reports absent for an entity that has been destroyed", function()
        local doomed = surface.create_entity { name = "wooden-chest", position = { 5, 5 }, force = "player" }
        doomed.destroy()
        assert.is_false(RitnLibEntity(doomed).isPresent,
            "a wrapper around a dead entity claims to be present, which is how a consumer "
            .. "ends up calling methods on an invalid LuaEntity")
    end)
end)
