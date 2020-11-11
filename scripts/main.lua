
------------------------------------------------------------
-- base
------------------------------------------------------------

local require = GLOBAL.require
local modinit = require("modinit")
local mod = modinit("auto_explore")

------------------------------------------------------------
-- header
------------------------------------------------------------
local print = _G.print;
local import = _G.import;


local push = table.insert
local tjoin = table.concat
local deg, rad = math.deg, math.rad
local sin, cos = math.sin, math.cos

local eventmgr = import("events")()



local tm = import("timer")
local removeTimer = tm.removeTimer
local setInterval = tm.setInterval
local setTimeout  = tm.setTimeout

local common = import("common")
local rpc = import("rpc");
local emotes = import("emotes")

local utils = reload("utils")
local clock = import("time")

local UserCommands = require "usercommands"

local AddChatCommand         = utils.AddChatCommandRepeat
local on_ls_player           = utils.on_ls_player
local choose_player_by_index = utils.choose_player_by_index
local go_point               = utils.go_point
local stop_moving            = utils.stop_moving
local pause_moving           = utils.pause_moving
local enum_ents              = utils.enum_ents
local find_by_tag            = utils.find_by_tag


local show_msg = utils.show_msg
local logger = import("log");

local easing = require("easing")
local Text = require "widgets/text"

local ax_lib = _M
local round = common.round

mod.import("check_tile");

------------------------------------------------------------
-- this
------------------------------------------------------------

this = this or {}
if not (this.eproxy) then
  this.eproxy = import("EventProxy")() 
end

local AddEventListener     = this.eproxy.createfn("")
local AddPrefabPostInit    = this.eproxy.createfn("AddPrefabPostInit")
local AddPlayerPostInit    = this.eproxy.createfn("AddPlayerPostInit")
local AddPrefabPostInitAny = this.eproxy.createfn("AddPrefabPostInitAny")
-- local key_em = import("events")("key_press")
local addKeyPressed = this.eproxy.createfn("key_press")



function log(...)
  logger.log(_M._path, ...)
end


log("auto_explore start")



------------------------------------------------------------
-- config
------------------------------------------------------------

local SERVER_SIDE = TheNet:GetIsServer() or TheNet:IsDedicated()
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())


local CFG_TEST_KEY = "U"

------------------------------------------------------------
-- tools
------------------------------------------------------------


function IsInGameplay()
  if not ThePlayer then
    return
  end
  if not (TheFrontEnd:GetActiveScreen().name == "HUD") then
    return
  end
  return true
end

function talk_say(msg)
  local p = ThePlayer
  local t = p.components.talker  
  t:Say(msg)
end

function client_move(pos)
  SendRPCToServer(RPC["DragWalking"], pos.x, pos.z, nil, false)
end


------------------------------------------------------------
-- func
------------------------------------------------------------

function set_auto_explore(enable)
  this.enable = enable

  this.last_target_tile = nil;
  this.tile_passed      = {}
  this.arr_next_tile    = {}
  this.arr_history      = {}

  this.enable_product  = this.enable
  this.enable_cost     = this.enable

  print("[test] set", this.enable)
  return this.enable
end

function toggle_auto_explore()
  this.enable = not (this.enable or false)

  set_auto_explore(this.enable)

  print("[test] toogle", this.enable)
  return this.enable
end

function onToggle(_, opt)
  -- if (opt == "r" or opt == "reset") then
    modget("auto_explore").import("main")
    talk_say("reload")
    return
  -- end

end

function remeber_pos(pos, tag)
  tag = tag or "noname"
  local v = ax_lib.convert_to_tile(pos)  
  local key = get_tile_key(v)
  local str = ("%s: %s"):format(tag, key)
  v.t__str = str

  if not (this.tile_passed[key]) then
    this.tile_passed[key] = v.t__str
    push(this.arr_next_tile, v)
  else
    -- todo  -- 
    print("already exits ?", pos, key)
  end
  return v;
end

function is_passed_pos(pos)
  local v = ax_lib.convert_to_tile(pos)  
  local key = get_tile_key(v)
  return (this.tile_passed[key])
end



function onPressKey()
  -- provent mistake press
  local curtime = GetTime()
  local cooldown = curtime - (this.presskey_lasttime or 0)
  if (cooldown < 1) then
    return
  end
  this.presskey_lasttime = curtime


  local modify = TheInput:IsKeyDown(KEY_CTRL)
  if (modify) then

    print("[test] reamin next_tile ------------->")
    for i,v in ipairs(this.arr_next_tile) do
      print(i, v, v.t__str)
    end
    t_ls(this.tile_passed)

    print("[test] history  >>>>>>>>>>>>>")
    for i,v in ipairs(this.arr_history) do
      print(i, v, v.t__str)
    end

    set_auto_explore(false)
    talk_say("clear history")
    return 
  end

  local ret = toggle_auto_explore()
  if (ret) then
    talk_say("Start auto explore")
  else
    talk_say("Stop auto explore")
  end
end


function calc_next_tile()
  if not (this.enable_product) then
    return 
  end

  local start_tile = this.last_target_tile
  if not (start_tile) then
    local p = ThePlayer
    local t = p.components.talker
    local x, y, z = p.Transform:GetWorldPosition()
    local pos = Vector3(x, y, z)
    start_tile = ax_lib.convert_to_tile(pos)
    remeber_pos(start_tile, "start")
  end

  -- todo 
  -- 1 check same edge
  -- 2 remove circle in graph
  local passed_filter = function (v, i)
    local passed = is_passed_pos(v);
    return not (passed)
  end

  local next_tile, reason = ax_lib.get_walkable_tile(start_tile, passed_filter)
  if (next_tile) then
    remeber_pos(next_tile, reason)
    this.last_target_tile = next_tile
  else
    this.enable_product = false
    local info = ("Auto move %s"):format(reason or "")
    talk_say(info)

    print("[test] auto move over", next_tile, reason)
  end

end

function goto_next_tile()
  if not (this.enable_cost) then
    return 
  end

  local p = ThePlayer
  local t = p.components.talker
  local x, y, z = p.Transform:GetWorldPosition()



  local target = this.arr_next_tile[1]
  if not (target) then
    return 
  end

  local dist2 = distsq(x, z, target.x, target.z) 
  if (dist2 < 10) then
    -- remove target reached
    local target_before = table.remove(this.arr_next_tile, 1)
    push(this.arr_history, target_before)

    target = this.arr_next_tile[1]
  end

  if (target) then
    client_move(target) 
  else  
    print("[test] no more target", #this.arr_next_tile)
  end
  
end


function onUpdate()
  if (this.enable) then
    calc_next_tile()
    goto_next_tile()
  end





end

-- result: speed is equal to dist per sceond move
-- if width interval  is 4, max speed is 10
-- update interval is less then 4/10
function onTestSpeed()
  local p = ThePlayer
  local t = p.components.talker
  local x, y, z = p.Transform:GetWorldPosition()

  local dist2 = 0
  if (this.last_pos) then
    local p2 = this.last_pos
    dist2 =  distsq(x, z, p2.x, p2.z) 
  end

  local dist = round(math.sqrt(dist2))
  local info = ("dist %d"):format(dist)
  t:Say(info)


  this.last_pos = Vector3(x, 0, z)

end


function on_test_api()
  if not IsInGameplay() then return end
  -- if (is_riding()) then
  --   local curtime = GetTime()
  --   local timeout = curtime - this.mountup_lasttime

  --   if (timeout < 2) then
  --     return
  --   end
  -- end

  print("[test] press key:", CFG_TEST_KEY)
  log("[test] press key:", CFG_TEST_KEY)


  local p = ThePlayer
  local x, y, z = p.Transform:GetWorldPosition()

  this.tile_width = 4
  this.tile_passed = this.tile_passed or {}

  local pos = Vector3(x, y, z)
  local pos = ax_lib.convert_to_tile(pos)
  local offset
  print(1, pos)
  print(2, ax_lib.is_pass_block(pos))
  -- print(3, ax_lib.test_pass(x, y, z), ax_lib.test_pass(x, 0, z))
  print(4, unpack(ax_lib.get_around_block(pos)) )
  print(5, ax_lib.get_tile_passable_type(pos) )

  local v, reason = ax_lib.get_walkable_tile(pos, function (v)
    return not (this.tile_passed[v])
  end)
  if (v) then
    local key = get_tile_key(v)
    this.tile_passed[key] = true 
    offset = Vector3(v.x - pos.x, 0, v.z - pos.z)
  end


  print(6, v, reason, offset )
  t_ls(this.tile_passed)

  -- toggle_mount()
end
------------------------------------------------------------
-- init
------------------------------------------------------------

function init()

  this.eproxy.reset()

  AddEventListener('playeractivated', function (inst, world)
    -- ThePlayer:ListenForEvent("isridingdirty", _f(function ()
    --   on_isridingdirty()
    -- end))
  end)


  utils.reg_key_press(CFG_TEST_KEY, true)
  addKeyPressed(CFG_TEST_KEY, function (keydown)
    if (keydown) then
      -- print("already 222 reg_key_press", key, b_keydown, keydown)
      onPressKey()
    end
  end)

  AddChatCommand("ax", onToggle)

  local interval = (FRAMES or 0.03) * 10
  removeTimer(this.tm_update)
  this.tm_update = setInterval(function ()
    onUpdate()
  end, interval)


end




init()

------------------------------------------------------------
-- reg chat cmd
------------------------------------------------------------


log("auto_explore 0.1")




--[[


modget("auto_explore").import("main")

import("log").debug()

]]

