require('core.setup-classes')
require("core.interfaces") -- beta
-- Activation de gvv s'il est présent
if script.active_mods["gvv"] then require("__gvv__.gvv")() end

-------------------------------------------------------------------------------
-- Tests
-- The integration tier, which runs inside a live game rather than against stubs.
-- rl-tests is never published, so this can never fire on a player's machine -- which
-- matters, because info.json keeps test/ out of the package and the fixtures would not
-- be there to require.
--
-- Registering from here rather than from rl-tests is what gives the fixtures the class
-- globals: _G is per-mod in Factorio, so RitnLibSurface and friends only exist inside a
-- mod that required the library.
if script.active_mods["factorio-test"] and script.active_mods["rl-tests"] then
    require("__factorio-test__/init")({
        "test.ft.api",
        "test.ft.prototypes",
        "test.ft.runtime",
        "test.ft.lualib",
    }, {
        load_luassert = true,
        game_speed = 100,
    })
end
