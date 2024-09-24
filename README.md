Data manipulation helper utility for Geometry Tower.
Allows you to decode embedded lua files and the save file (`Android/data/com.cyberjoy.geometrytower/files/data.dat`).

# Usage
`luvit gtcrypt.lua action ...`

Actions:
 - `decrypt input output` - decrypt a file
 - `encrypt input output` - encrypt a file
 - `saveDecode input output` - decrypt and decode a savegame into yaml
 - `saveEncode input output` - encode and encrypt a savegame from yaml

Example:
`luvit gtcrypt.lua decrypt Lua/launch.lua launch.lua`

# Requirements
[Luvit](https://luvit.io/), [lyaml](https://github.com/gvvaughan/lyaml)