
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

this = this or {}

this.tile_width = this.tile_width or 4


------------------------------------------------------------
-- func
------------------------------------------------------------

 -- customcheckfn, allow_water, allow_boats
  -- local pos2 = FindNearbyLand(pos, range)
--   local offset = FindWalkableOffset(pos, start_angle, radius, attempts, check_los, ignore_walls)
-- print("[test] ....222....", FindWalkableOffset(pos, start_angle, radius, attempts, check_los, ignore_walls))
-- -- print("[test] ....333....", FindNearbyLand(pos, range))

--   local pos2 = Vector3(pos.x+offset.x, y, pos.z+offset.z)
--   -- rpc.send("set_unit_offset", pos2.x, pos2.z)
--   SendRPCToServer(RPC["DragWalking"], pos2.x, pos2.z, nil, false)
--   this.ax_last_pos = pos2

function test_pass(x, y, z)
	if (TheWorld.Map:IsPointNearHole(Vector3(x, 0, z))) then
		return false
	end
  return TheWorld.Map:IsAboveGroundAtPoint(x, 0, z)
end



-- function is_pass(pos, width)
--   local x, y, z = pos:Get()

--   TheWorld.Map:IsAboveGroundAtPoint(x, 0, z)
--   and not TheWorld.Map:IsPointNearHole(Vector3(x, 0, z))
--   return Vector3(x, pos.y, z)
-- end

function convert_to_tile(pos, width)
	local width = width or this.tile_width
  local x = pos.x - pos.x%width + width/2
  local z = pos.z - pos.z%width + width/2
  return Vector3(x, 0, z)
end

function get_tile_key(pos)
	local width = this.tile_width
	local tile = convert_to_tile(pos, width)
  local key = ("%d,%d"):format(tile.x, tile.z)
  return key
end



-- todo calc edge dist level from edge
function get_level_by_side_id(i)
	return (i+1)%2 + 1
end

function get_around_tile(pos)
	local arr = {}
	local width = this.tile_width
	local org = convert_to_tile(pos, width)

	-- -- 4 side
	-- push(arr, Vector3(org.x-width, 0, org.z))
	-- push(arr, Vector3(org.x, 0, org.z+width))
	-- -- push(arr, Vector3(org.x, 0, org.z))
	-- push(arr, Vector3(org.x+width, 0, org.z))
	-- push(arr, Vector3(org.x, 0, org.z-width))

	-- 8 side
	push(arr, Vector3(org.x-width, 0, org.z+width))
	push(arr, Vector3(org.x,       0, org.z+width))
	push(arr, Vector3(org.x+width, 0, org.z+width))
	push(arr, Vector3(org.x+width, 0, org.z))
	push(arr, Vector3(org.x+width, 0, org.z-width))
	push(arr, Vector3(org.x,       0, org.z-width))
	push(arr, Vector3(org.x-width, 0, org.z-width))
	push(arr, Vector3(org.x-width, 0, org.z))

  return arr
end

function is_passable_tile(pos)
	local tile = convert_to_tile(pos, this.tile_width)

  return test_pass(tile.x, 0, tile.z)
end


-- todo check edge & last edge in same line
function get_tile_passable_type(pos)
	if not (is_passable_tile(pos)) then
		return "block", -1
	end

	local arr = get_around_tile(pos)
	for i, v in ipairs(arr) do
		if not (is_passable_tile(v)) then
			return "edge", get_level_by_side_id(i)
		end
	end
  return "blank", 0
end

-- also passable tile but has tile around
-- names edge passable tile
function is_edge_tile(pos)
	if not (is_passable_tile(pos)) then
		return false
	end

	local arr = get_around_tile(pos)
	for i, v in ipairs(arr) do
		if not (is_passable_tile(pos)) then
			return true
		end
	end
  return false
end
-- todo check edge & last edge in same line
function get_walkable_tile(pos, filter)
	local arr = get_around_tile(pos)
	local arr_blank = {}
	local arr_blank = {}
	
	for i, v in ipairs(arr) do
		local tile_type, level = get_tile_passable_type(v)
		if (tile_type == "edge" and filter(v, "edge", i)) then
			return v, "edge"
		end
		if (tile_type == "blank") then
			push(arr_blank, {i, v, tile_type})
		end
	end

	if (#arr_blank > 0) then
		for j, params in ipairs(arr_blank) do
			local i, v, tile_type = unpack(params)
			if (filter(v, tile_type, i)) then
				return v, "blank"
			end
		end
		return nil, "done"
	end
  return nil, "blocked"
end



--[[

	edge > blank > block

	blank but not passed


function onUpdate1_realtime_cost()
  if not (this.enable) then
    return 
  end

  local p = ThePlayer
  local t = p.components.talker
  local x, y, z = p.Transform:GetWorldPosition()
  local pos = Vector3(x, y, z)
  local cur_tile = ax_lib.convert_to_tile(pos)

  local offset
  local last_pos = this.last_dest_pos or pos;
  local v0 = this.last_target_tile or cur_tile;

  remeber_pos(v0)

  -- todo check same edge
  local passed_filter = function (v, vtype, i)
    local passed = is_passed_pos(v);
    return not (passed)
  end
  local v, reason = ax_lib.get_walkable_tile(v0, passed_filter)
  if (v) then
    remeber_pos(v)
    offset = Vector3(v.x - v0.x, 0, v.z - v0.z)
    local pos2 = Vector3(x+offset.x, 0, z+offset.z)
    client_move(pos2)
    this.last_dest_pos = pos2
    this.last_target_tile = v
  else
    this.enable = false
  end

  local info = ("move %s"):format(reason or "")
  t:Say(info)

  print(">>>", v, reason, offset)
end


  local pos = this.ax_last_pos or Vector3(x, y, z)
  local start_angle = (90/360) * 2 * PI
  -- local start_angle = 0

  local range = 8
  local radius = range
  local attempts = 4
  local check_los = true
  local ignore_walls = true

 -- customcheckfn, allow_water, allow_boats
  -- local pos2 = FindNearbyLand(pos, range)
--   local offset = FindWalkableOffset(pos, start_angle, radius, attempts, check_los, ignore_walls)
-- print("[test] ....222....", FindWalkableOffset(pos, start_angle, radius, attempts, check_los, ignore_walls))
-- -- print("[test] ....333....", FindNearbyLand(pos, range))

--   local pos2 = Vector3(pos.x+offset.x, y, pos.z+offset.z)
--   -- rpc.send("set_unit_offset", pos2.x, pos2.z)
--   SendRPCToServer(RPC["DragWalking"], pos2.x, pos2.z, nil, false)
--   this.ax_last_pos = pos2


function FindPlayersInRange(x, y, z, range, isalive)
    return FindPlayersInRangeSq(x, y, z, range * range, isalive)
end

function IsAnyPlayerInRangeSq(x, y, z, rangesq, isalive)
    for i, v in ipairs(AllPlayers) do
        if (isalive == nil or isalive ~= (v.replica.health:IsDead() or v:HasTag("playerghost"))) and
            v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < rangesq then
            return true
        end
    end
    return false
end

function IsAnyPlayerInRange(x, y, z, range, isalive)
    return IsAnyPlayerInRangeSq(x, y, z, range * range, isalive)
end

-- Get a location where it's safe to spawn an item so it won't get lost in the ocean
function FindSafeSpawnLocation(x, y, z)
    local ent = x ~= nil and z ~= nil and FindClosestPlayer(x, y, z) or nil
    if ent ~= nil then
        return ent.Transform:GetWorldPosition()
    elseif TheWorld.components.playerspawner ~= nil then
        -- we still don't have an enity, find a spawnpoint. That must be in a safe location
        return TheWorld.components.playerspawner:GetAnySpawnPoint()
    else
        -- if everything failed, return origin  
        return 0, 0, 0
    end
end

function FindNearbyLand(position, range)
    local finaloffset = FindValidPositionByFan(math.random() * 2 * PI, range or 8, 8, function(offset)
        local x, z = position.x + offset.x, position.z + offset.z
        return TheWorld.Map:IsAboveGroundAtPoint(x, 0, z)
            and not TheWorld.Map:IsPointNearHole(Vector3(x, 0, z))
    end)
    if finaloffset ~= nil then
        finaloffset.x = finaloffset.x + position.x
        finaloffset.z = finaloffset.z + position.z
        return finaloffset
    end
end
        return TheWorld.Map:IsAboveGroundAtPoint(x, 0, z)
            and not TheWorld.Map:IsPointNearHole(Vector3(x, 0, z))
    end)


-- This function fans out a search from a starting position/direction and looks for a walkable
-- position, and returns the valid offset, valid angle and whether the original angle was obstructed.
-- starting_angle is in radians
function FindWalkableOffset(position, start_angle, radius, attempts, check_los, ignore_walls, customcheckfn, allow_water, allow_boats)
    return FindValidPositionByFan(start_angle, radius, attempts,
            function(offset)
                local x = position.x + offset.x
                local y = position.y + offset.y
                local z = position.z + offset.z
                return (

TheWorld.Map:IsAboveGroundAtPoint(x, y, z, allow_water) 
or (allow_boats 
and TheWorld.Map:GetPlatformAtPoint(x,z) ~= nil))
and (not check_los or
TheWorld.Pathfinder:IsClear(
  position.x, position.y, position.z,
  x, y, z,
{ ignorewalls = ignore_walls ~= false, ignorecreep = true, allowocean = allow_water }))
and (customcheckfn == nil or customcheckfn(Vector3(x, y, z)))
            end)
end


]]


print(111, _M)

return _M