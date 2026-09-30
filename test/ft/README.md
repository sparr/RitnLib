# The integration tier

69 tests that ask a real Factorio what RitnLib actually does, on top of
[factorio-test](https://mods.factorio.com/mod/factorio-test). Headless, no display, a few
seconds end to end.

```bash
npm install                    # once: fetches factorio-test-cli
test/ft/run.sh                 # the whole suite
test/ft/run.sh -v              # with the game's own log lines
test/ft/run.sh "lualib"        # only tests matching a Lua pattern
test/ft/run.sh -b              # stop at the first failure
```

`RL_FACTORIO` points at the game binary, `RL_FT_DATA` at the throwaway data directory the
run happens in (`~/.cache/ritnlib-factorio-test` by default, deliberately outside the repo
-- the runner symlinks the mod under test into that directory's mods folder, so a data
directory inside the repo would make the repo contain itself). Two runs cannot share one
data directory.

## Testing a library

RitnLib has no behavior of its own to observe: it ships no prototypes, adds no entities and
draws nothing. Its behavior is its public surface, so the suite is built around being a
consumer of it.

- `test/ft/rl-tests/` is that consumer. Its `data.lua` drives the data-stage builder
  classes -- the half of the library nothing else here could reach -- and
  `test/ft/prototypes.lua` then checks at runtime that the game really ended up with what
  those builders claimed to make.
- `control.lua` registers the fixtures, guarded on both `factorio-test` and `rl-tests`
  being loaded. `rl-tests` is never published, so the hook can never fire on a player's
  machine -- which matters, because `info.json` keeps `test/` out of the package.
- `.gitattributes` keeps `test/` and the npm files out of the released zip. That is the
  mechanism this repo actually uses: `.github/workflows/release.yml` builds the mod with
  `git archive`, which honors `export-ignore` and ignores `info.json`'s `package` field.
- Registering from *this* mod rather than from `rl-tests` is what gives the fixtures the
  class globals at all. `_G` is per-mod in Factorio: `RitnLibSurface` and the rest exist
  only inside a mod that has required the library. A fixture living in `rl-tests` would
  see nothing but nils.

## The files

- `api.lua` -- the twelve classes `core/setup-classes.lua` registers, that they are
  callable, and that every documented `ritnlib.defines` path resolves to a require string.
  A missing branch here is a silently broken `require` in somebody else's mod.
- `prototypes.lua` -- what the data-stage builders produced: the four `extend()` builders
  that create prototypes outright, and the mutating methods against vanilla recipes and
  technologies.
- `runtime.lua` -- the LuaClass wrappers against real surfaces, forces and entities.
- `lualib.lua` -- the table, string and json helpers consumers require by path.

## Things the tests pin because they are surprising

- `tbl.indexOf` returns **-1** for a miss, not nil. `if tbl.indexOf(t, v) then` is
  therefore true for a value that is not in the table.
- `RitnLibSurface` takes a `LuaSurface` and nothing else. Handed a surface index it logs
  "not LuaSurface !" and returns an object whose every field is nil, with no error.
  `isPresent` is the only way to find out.
- `RitnLibEntity` around a destroyed entity reports `isPresent = false`, which is what
  keeps a consumer from calling methods on an invalid `LuaEntity`.
- 2.1 replaced `LuaRecipePrototype::category` with a `categories` array, so
  `prototypes.lua` reads whichever the running version offers instead of assuming.
  RitnLib itself never reads that field, which is why the port did not have to.
- A vanilla 2.1 load has no `tool` prototypes at all, so `data.raw.tool` is nil. The type
  still exists and a mod may define one; nothing in the base game does since 2.1.7 made
  science packs plain items. `RitnProtoTech`'s four pack methods indexed that table
  directly, so each raised "attempt to index field 'tool' (a nil value)" and stopped the
  load. `rl-tests/data.lua` drives all four, which is why reaching the assertions is most
  of what they check.

The API used by `rl-tests/data.lua` is the one the code has, which is not the one
`docs/guides/first-prototype` describes. See the bug report in the port workspace.
