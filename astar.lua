local Heap = {}
Heap.__index = Heap

-- 创建一二叉堆,n代表数量
local function makeHeap()
    return setmetatable( { n = 0 }, Heap)
end

-- push操作 block - 格子 ， f = g + h
function Heap:push(block,f)
    local n = self.n + 1
    self.n = n
    self[n] = { block = block , f = f }

    -- 上浮操作:新元素如果比父节点小 则交换 直到放入正确位置
    local i = n
    while i > 1 do
        local p = math.floor(i  / 2)
        if self[p].f <= self[i].f then
            break
        end
        self[p] , self[i] = self[i] , self[p]  -- swap 交换操作
        i = p                                  -- 更新i 继续while
    end
end

function Heap:pop()
    local n = self.n
    if n == 0 then
        return nil
    end
    local top = self[1]         -- 标记 ，最后返回
    self[1] = self[n]           -- 将 self[1] 换为 self[n]，再将self[1]下沉
    self[n] = nil
    n = n - 1
    self.n = n

    -- 下沉
    local i = 1
    while true do
        local lc = 2 * i
        local rc = 2 * i + 1
        local smaller = i

        if lc <= n and self[lc].f < self[smaller].f then smaller = lc end
        if rc <= n and self[rc].f < self[smaller].f then smaller = rc end
        if smaller == i then
            break
        end

        self[i] , self[smaller] = self[smaller] , self[i]
        i = smaller
    end

    return top.block, top.f
end

function Heap:empty()
    return self.n == 0
end

-- tips: lua中表 当做key时，是按照“引用”进行查找的；如果是直接拿{row,col}当做表的键，永远查不到
-- 可以使用字符串来代替 - 按照内容查找
local function key(col,row)
    return col .. "," .. row        -- {col,row} -> "col,row"
end

-- map : Hex 地图对象 Hex.load(path)
-- start : 起点 { start_pos[1] , start_pos[2] }
-- goal : 终点  { goal_pos[1] , goal_pos[2] }
local function astar(map , start, goal)
    local sc , sr = start[1] , start[2]
    local gc , gr = goal[1] , goal[2]

    -- 检查是否越界
    if not map:in_bounds(sc,sr) then return nil, "起点越界" end
    if not map:in_bounds(gc,gr) then return nil, "终点越界" end
    if map:is_blocked(sc,sr) then return nil, "起点被阻挡" end
    if map:is_blocked(gc,gr) then return nil, "终点被阻挡" end

    local open = makeHeap()         -- openlist
    local came = {}                 -- came["c,r"] 前驱节点
    local g = {}                    -- g值
    local closed = {}               -- closelist closed["c,r"] = true 表示该格已确定最短，不再处理

    local skey = key(sc,sr)
    g[skey] = 0                     -- 起点到自己 - 0
    open:push(start,map:distance(start,goal))   -- 起点入队 f = 0 + h

    -- 只要openlist中还有就继续
    while not open:empty() do
        local cur = open:pop()
        local cur_key = key(cur[1],cur[2])           -- 拿到当前位置的信息，组合成字符串

        -- 如果关闭列表里没有cur_key，加入关闭列表，并判断是否到终点
        if not closed[cur_key] then
            closed[cur_key] = true                   -- 已探索标记

            -- 判断是否已经到达终点
            if cur[1] == gc and cur[2] == gr then
                local rpath = {}                        -- 路径列表，准备回溯
                local node = cur
                while node do
                    rpath[#rpath + 1] = node
                    node = came[key(node[1],node[2])]   -- 不断回溯父节点 直到为 nil
                end

                local path = {}                         -- 最终路径 rpath需要翻转

                for i = #rpath , 1 , -1 do              -- for(int i = repath.length();i >= 1;i--)
                    path[#path + 1] = rpath[i]
                end

                return path                             -- 返回路径
            end

            -- 如果还没到终点,寻找周围的可行路径（节点），加入openlist
            for _, next_block in ipairs(map:neighbors(cur[1],cur[2])) do
                local next_key = key(next_block[1],next_block[2])
                if not closed[next_key] then
                    local cost = g[cur_key] + 1                -- 决定是否更新周围节点的g值 - 此路径上为当前节点+1步的代价
                    if g[next_key] == nil or cost < g[next_key] then  -- 如果nk没有被探索过（nil）或者此路径的cost（g）小于原来它的g，则更新
                        g[next_key] = cost
                        came[next_key] = cur                    -- 更改父节点
                        open:push(next_block, cost + map:distance(next_block, goal))
                    end
                end
            end
        end
    end

    -- openlist 没了 则证明没有可解路径
    return nil,"无可解路径"
end

return astar