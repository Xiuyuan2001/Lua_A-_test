-- 创建一个空表 当做本模块最后的输出
local Hex = {}

-- lua中面向对象/方法的固定写法
    -- 当通过一个hex对象去找它没有的字段时，就去Hex这张表里找
    -- 这样我们写 function Hex:xxx()方法时，才能被Hex.load() 造出来的对象找到
Hex.__index = Hex

local oddq_dirs = {
    [0] = {{1,0},{1,-1},{0,-1},{-1,-1},{-1,0},{0,1}},
    [1] = {{1,1},{1,0},{0,-1},{-1,0},{-1,1},{0,1}},
}

-- 大端序读取二进制数据
local function read_u16_be(s,pos)
    -- string.byte(s,i,j) 表示 返回字符串 s 第 i 到 第 j 个字符的ASCII码 - 即 bi_high = pos ; bi_low = pos + 1
    local b_high , b_low = string.byte(s,pos,pos+1)
    return b_high*256 + b_low
end

-- Hex.load(path) 读取map.byte，返回一个地图对象
function Hex.load(path)
    -- io.open(路径，模式) - rb：read binary 以二进制只读方式打开
    -- assert + 操作 + 出错信息
    local f = assert(io.open(path,"rb"),"无法打开地图文件:"..tostring(path))

    -- f:read 将整个文件一次性读成一个字符串（*a = all 保存全部内容）
    local data = f:read("*a")
    f:close()

    assert(data and #data >= 4,"文件过小：缺失四字节头部")

    local file_row = read_u16_be(data,1)
    local file_col = read_u16_be(data,3)

    assert(data and #data >= 4 + file_col * file_row,"文件过小：地形数据不足")

    -- 调换行列
    local cols = file_row
    local rows = file_col

    -- 创建“地图对象”这张表，并把它和Hex关联（setmetatable）
    -- setmetatable(t,mt) 做两件事
        -- 创建（传入）一张表 t 作为对象本身
        -- 把 mt(Hex) 设为它的元表（metatable），然后返回这张表，赋给self
    -- 如果使用方法 self:in_bounds() 时，lua先去self这张表里找in_bounds，找不到则去元表里（Hex）找；在Hex中找到了Hex:in_bounds这个函数，调用它
    -- 方法存储在元表Hex里，数据存储在self里，setmetatable通过元表将两者联系起来
    local self = setmetatable({
        cols = cols, rows = rows,   -- 地图的真实宽高 - 实际已经调换
        raw_field_row = file_row,   -- 文件里读取出来的原始字段
        raw_field_col = file_col,
        cells = {},                 -- 一维表，存地图地形信息
    },Hex)
    
    -- 把二维地图“摊平”成一维存进self.cells
    for col = 0, cols - 1 do
        for row = 0, rows - 1 do
            local k = col * rows + row                  -- 行列调换
            self.cells[k] = string.byte(data,k+5)       -- k+5 跳过 header
        end
    end

    return self
end

-- 判断点是否在地图内部
function Hex:in_bounds(col,row)
    return col >= 0 and col < self.cols and row >= 0 and row < self.rows
end

-- 取某个格子的原始值（地形）;先判断是否合法，再返回值
function Hex:value(col,row)
    if not self:in_bounds(col,row) then
        return nil
    end
    return self.cells[col * self.rows + row]
end

-- 是否被阻挡
function Hex:is_blocked(col,row)
    local v = self:value(col,row)
    return v == nil or v > 0        -- 越界或者被阻挡 返回true
end

function Hex:neighbors(col,row)
    local dirs = oddq_dirs[col % 2]  -- 对应奇偶
    local out = {}

    for _, d in ipairs(dirs) do      -- 遍历dir中的6个元素（方向） ，每轮都是 下表 + 值 的形式，下表用不上，故可以使用 _ 来表示 
        local nc = col + d[1]
        local nr = row + d[2]

        if self:in_bounds(nc,nr) and not self:is_blocked(nc,nr) then
            out[#out + 1] = { nc,nr }   -- 将合法的邻居加入到out表中
        end
    end
    return out
end


-- 坐标转换 oddq -> cube
local function oddq_to_cube(col,row)
    local q = col
    local r = row - (col - (col & 1)) / 2       -- 取整 col = 3 -> 011 & 001 = 001 = 1 ---> (3-1) / 2 = 1
    local s = -q-r
    return q , r , s
end

-- 计算两个格子之间的最短距离 - {col,row}
function Hex:distance(a,b)
    local aq , ar , as = oddq_to_cube(a[1],a[2])
    local bq , br , bs = oddq_to_cube(b[1],b[2])

    return math.max(math.abs(aq - bq) , math.abs(ar - br) , math.abs(as - bs))
end 


return Hex;

