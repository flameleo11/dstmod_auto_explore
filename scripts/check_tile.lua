
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


--           -90
--   -135  s   y1     -45

-- -180  -1    +      x1     0

--     135    -1      45
--            90

local angle_2_tile_offset = {
  [1] = { x= 1, y=0, z= 0};
  [2] = { x= 1, y=0, z=-1};
  [3] = { x= 0, y=0, z=-1};
  [4] = { x=-1, y=0, z=-1};
  [5] = { x=-1, y=0, z= 0};
  [6] = { x=-1, y=0, z= 1};
  [7] = { x= 0, y=0, z= 1};
  [8] = { x= 1, y=0, z= 1};
}

------------------------------------------------------------
-- func
------------------------------------------------------------

function get_angle_index(x)
  return (math.floor((x+22.5)/45) % 8)
end

function get_angle_id(x)
  return get_angle_index(x+360) + 1
end

function reset_array_from_id(arr, start_i)
  local len = #arr
  local arr2 = {}
  for i, v in ipairs(arr) do
    local i2 = (i-start_i+len)%len + 1
    -- v.id = i
    arr2[i2] = v
  end
  return arr2
end

function get_8side_offset_by_angle(angle)
  local start_id = get_angle_id(angle)
  local arr = reset_array_from_id(angle_2_tile_offset, start_id)
  return arr
end

function get_around_tiles_by_facing(pos, facing)
  local arr = {}
  local w = this.tile_width
  local org = convert_to_tile(pos, width)

  local offset_base = get_8side_offset_by_angle(facing)

  -- 8 sides
  for i, v in ipairs(offset_base) do
    arr[i] = Vector3(org.x + v.x*w, 0, org.z + v.z*w)
  end
  return arr
end


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



-- todo start from facing angle tile
function get_around_tile(pos, facing)
	local arr = {}
	local width = this.tile_width
	local org = convert_to_tile(pos, width)

	-- 8 side
	push(arr, Vector3(org.x-width, 0, org.z))
	push(arr, Vector3(org.x-width, 0, org.z+width))
	push(arr, Vector3(org.x,       0, org.z+width))
	push(arr, Vector3(org.x+width, 0, org.z+width))
	push(arr, Vector3(org.x+width, 0, org.z))
	push(arr, Vector3(org.x+width, 0, org.z-width))
	push(arr, Vector3(org.x,       0, org.z-width))
	push(arr, Vector3(org.x-width, 0, org.z-width))

  return arr
end


function get_cross_tile_x1(pos)
	local arr = {}
	local width = this.tile_width
	local org = convert_to_tile(pos, width)

	-- 4 side cross
	push(arr, Vector3(org.x,       0, org.z+width))
	push(arr, Vector3(org.x,       0, org.z-width))
	push(arr, Vector3(org.x-width, 0, org.z))
	push(arr, Vector3(org.x+width, 0, org.z))

  return arr
end

function get_cross_tile_x2(pos)
	local arr = {}
	local width = this.tile_width
	local org = convert_to_tile(pos, width)

	-- 4 side cross
	push(arr, Vector3(org.x-width, 0, org.z-width))
	push(arr, Vector3(org.x-width, 0, org.z+width))
	push(arr, Vector3(org.x+width, 0, org.z-width))
	push(arr, Vector3(org.x+width, 0, org.z+width))

  return arr
end

function is_passable_tile(pos)
	local tile = convert_to_tile(pos, this.tile_width)

  return test_pass(tile.x, 0, tile.z)
end


-- todo check edge & last edge in same line
function get_tile_passable_type(pos)
	if not (is_passable_tile(pos)) then
		return "block", 0
	end

	local arr = get_cross_tile_x1(pos)
	for i, v in ipairs(arr) do
		if not (is_passable_tile(v)) then
			return "edge", 1
		end
	end
	local arr = get_cross_tile_x2(pos)
	for i, v in ipairs(arr) do
		if not (is_passable_tile(v)) then
			return "edge", 2
		end
	end

  return "blank", 9
end

-- todo check edge & last edge in same line
function get_walkable_tile(pos, filter, facing)
	local arr_around = get_around_tiles_by_facing(pos, facing)
	local arr_blank = {}
	local arr_blank = {}

	local arr = {}
	for i, v in ipairs(arr_around) do
		if (filter(v, i)) then
			local tile_type, dist_to_block = get_tile_passable_type(v)
			if (dist_to_block > 0) then
				v.w1 = dist_to_block
				v.w2 = i
				v.type = tile_type

				push(arr, v)
			end
		end
	end

	if not (#arr > 0) then
		return nil, "all passed !", -1
	end

	table.sort(arr, function (a, b)
		if (a.w1 == b.w1) then
			return a.w2 < b.w2
		end
		return a.w1 < b.w1
	end)

	local v = arr[1]
	if (v.type == "block") then
		return nil, "done", 0
	end
	return v, v.type, v.w1
end




--[[

-- todo clean cache loc history



]]



return _M