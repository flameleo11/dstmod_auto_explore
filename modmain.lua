------------------------------------------------------------
-- header
------------------------------------------------------------

local require = GLOBAL.require
local modinit = require("modinit")
local mod = modinit("auto_explore")

------------------------------------------------------------
-- main
------------------------------------------------------------

local import = _G.import;
local logger = import("log");
local eventmgr = import("events")()


require("tprint")

mod.import("main")


--[[

/drive_d/work/dst/my_mod/auto_explore/modmain.lua
modget("auto_explore").import("main")

import("log").debug()

]]

