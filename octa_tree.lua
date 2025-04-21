
for _, region: Region<T> in ipairs(regions) do
    if region.Nodes ~= nil then
        for _, node: Node<T> in ipairs(region.Nodes) do
            if (node.Position - position).Magnitude < radius then
                coroutine.yield(node)
            end
        end
    end
end
end)
end

function Octree:GetNearest<T>(position: Vector3, radius: number, maxNodes: number?): { Node<T> }
local nodes = self:SearchRadius(position, radius)
table.sort(nodes, function(n0: Node<T>, n1: Node<T>)
local d0 = (n0.Position - position).Magnitude
local d1 = (n1.Position - position).Magnitude
return d0 < d1
end)
if maxNodes ~= nil and #nodes > maxNodes then
return table.move(nodes, 1, maxNodes, 1, table.create(maxNodes))
end
return nodes
end

function Octree:_getRegion<T>(maxLevel: number, position: Vector3): Region<T>
local function GetRegion(regionParent: Region<T>?, regions: { Region<T> }, level: number): Region<T>
local region: Region<T>? = nil
-- Find region that contains the position:
for _, r in regions do
    if IsPointInBox(position, r.Center, r.Size) then
        region = r
        break
    end
end
if not region then
    -- Create new region:
    local size = (self :: OctreeInternal<T>).Size / (2 ^ (level - 1))
    local origin = if regionParent
        then regionParent.Center
        else Vector3.new(RoundTo(position.X, size), RoundTo(position.Y, size), RoundTo(position.Z, size))
    local center = origin
    if regionParent then
        -- Offset position to fit the subregion within the parent region:
        center += Vector3.new(
            if position.X > origin.X then size / 2 else -size / 2,
            if position.Y > origin.Y then size / 2 else -size / 2,
            if position.Z > origin.Z then size / 2 else -size / 2
        )
    end
    local newRegion: Region<T> = {
        Regions = {},
        Level = level,
        Size = size,
        -- Radius represents the spherical radius that contains the entirety of the cube region
        Radius = math.sqrt(size * size + size * size + size * size),
        Center = center,
        Parent = regionParent,
        Nodes = if level == MAX_SUB_REGIONS then {} else nil,
    }
    table.freeze(newRegion)
    table.insert(regions, newRegion)
    region = newRegion
end
if level == maxLevel then
    -- We've made it to the bottom-tier region
    return region :: Region<T>
else
    -- Find the sub-region:
    return GetRegion(region :: Region<T>, (region :: Region<T>).Regions, level + 1)
end
end
local startRegion = GetTopRegion(self, position, true)
return GetRegion(startRegion, startRegion.Regions, 2)
end

Octree.__iter = Octree.ForEachNode

return {
new = CreateOctree,
}