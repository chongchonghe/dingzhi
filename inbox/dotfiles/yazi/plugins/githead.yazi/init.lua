-- shim for loaders that expect plugins to expose an init.lua entrypoint
local source = debug.getinfo(1, "S").source:sub(2)
local dir = source:match("(.+[\\/])") or "./"

return dofile(dir .. "main.lua")
