-- Stands in for a consumer mod at the data stage.
--
-- RitnLib ships no prototypes of its own; everything under classes/prototypes/ exists to
-- be called by other mods, so the only honest way to test that half of the library is to
-- be one of those mods. Everything touched here is asserted at runtime by
-- test/ft/prototypes.lua.
--
-- Note this uses the API the code actually has, not the one docs/guides/first-prototype
-- describes. See BUGS.md in the port workspace: that guide documents setResult, setStack,
-- setGroup, setPrerequisites, setResearchUnit, addUnlockedRecipe and a closing :new(),
-- none of which exist.
require("__RitnLib__.defines")

local RitnProtoRecipeCategory = require(ritnlib.defines.class.prototype.category)
local RitnProtoFuelCategory = require(ritnlib.defines.class.prototype.fuelCategory)
local RitnProtoItemGroup = require(ritnlib.defines.class.prototype.group)
local RitnProtoItemSubgroup = require(ritnlib.defines.class.prototype.subgroup)
local RitnProtoRecipe = require(ritnlib.defines.class.prototype.recipe)
local RitnProtoTech = require(ritnlib.defines.class.prototype.technology)

-- the four builders that create prototypes outright
RitnProtoRecipeCategory:extend("rl-tests-category", "z-rl-tests")
RitnProtoFuelCategory:extend("rl-tests-fuel", "z-rl-tests")
RitnProtoItemGroup:extend("rl-tests-group", "z-rl-tests", "__base__/graphics/icons/iron-plate.png", 64)
RitnProtoItemSubgroup:extend("rl-tests-subgroup", "rl-tests-group", "z-rl-tests")

-- and the mutating half, against vanilla prototypes. The recipe path is the one that
-- matters most for 2.1: the game merged a recipe's `category` and `additional_categories`
-- into a single `categories` array, and these methods read and write recipe tables whole.
RitnProtoRecipe("iron-gear-wheel")
    :addIngredient({ "copper-plate", 1 })
    :changeSubgroup("rl-tests-subgroup", "z-rl-tests")

RitnProtoRecipe("copper-cable"):setEnabled(false)

RitnProtoTech("logistics-2")
    :addPrerequisite("steel-processing")
    :addPack("logistic-science-pack", 1)

-- The other three science-pack methods. All four validated their argument by indexing
-- data.raw.tool, which 2.1.7 left nil by making science packs plain items, so all four
-- have to be driven here or a regression in the lookup goes unnoticed.
RitnProtoTech("logistics-3"):replacePack("chemical-science-pack", "military-science-pack")

-- removePackLab and addPackLab act on data.raw.lab rather than on the technology, so the
-- instance they are called on is incidental. Taking a pack out and putting it back at the
-- front is observable both ways: a lookup that returned early would leave the pack where
-- it started.
RitnProtoTech("logistics-2")
    :removePackLab("space-science-pack")
    :addPackLab("space-science-pack", 1)
    :addPackLab("rl-tests-no-such-pack")
