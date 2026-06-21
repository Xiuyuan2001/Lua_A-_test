local Hex = require("hex")
local astar = require("astar")

local mapfilepath = "./map.byte"
local map = Hex.load(mapfilepath)       -- 读地图 得到地图对象hex

-- 将第i个命令行参数转为数字；没有则用默认default
local function num(i,default)
    return (arg[i] and tonumber(arg[i])) or default
end

local start = {num(1,0),num(2,0)}                       -- 将第1、2个命令行输入转换为起点坐标，默认使用(0,0)
local goal = {num(3,map.cols - 1),num(4,map.rows - 1)}  -- 将第3、4个命令行输入转换为起点坐标，默认使用右下角

local path = astar(map,start,goal)

if not path then
    print("寻路失败")
else    
    print("寻路成功")
end