--!strict

local Types = require(script.Parent.Lib.Types)
local iif = require(script.Parent.Lib.iif)

type Point = Types.Point
type Line = Types.Line
type Intersection = Types.Intersection
type Region = Types.Region

type EpsilonClass = {
	__index: EpsilonClass,
	new: (eps: number?) -> Epsilon,
	epsilon: (self: Epsilon, eps: number?) -> number,
	pointAboveOrOnLine: (self: Epsilon, point: Point, left: Point, right: Point) -> boolean,
	pointBetween: (self: Epsilon, point: Point, left: Point, right: Point) -> boolean,
	pointsSameX: (self: Epsilon, p1: Point, p2: Point) -> boolean,
	pointsSameY: (self: Epsilon, p1: Point, p2: Point) -> boolean,
	pointsSame: (self: Epsilon, p1: Point, p2: Point) -> boolean,
	pointsCompare: (self: Epsilon, p1: Point, p2: Point) -> number,
	pointsCollinear: (self: Epsilon, a: Point, b: Point, c: Point) -> boolean,
	linesIntersect: (self: Epsilon, a: Line, b: Line) -> (boolean, Intersection?),
	pointInsideRegion: (self: Epsilon, point: Point, region: Region) -> boolean,
}

type EpsilonInstance = {
	eps: number,
}

export type Epsilon = typeof(setmetatable({} :: EpsilonInstance, {} :: EpsilonClass))

local Epsilon = {} :: EpsilonClass
Epsilon.__index = Epsilon

function Epsilon.new(eps: number?): Epsilon
	return setmetatable({
		eps = eps or 0.0000000001,
	}, Epsilon)
end

function Epsilon:epsilon(eps: number?): number
	if eps then
		self.eps = eps
	end

	return self.eps
end

function Epsilon:pointAboveOrOnLine(point: Point, left: Point, right: Point): boolean
	local Ax = left.X
	local Ay = left.Y
	local Bx = right.X
	local By = right.Y
	local Cx = point.X
	local Cy = point.Y

	return (Bx - Ax) * (Cy - Ay) - (By - Ay) * (Cx - Ax) >= -self.eps
end

function Epsilon:pointBetween(point: Point, left: Point, right: Point): boolean
	-- p must be collinear with left->right
	-- returns false if p == left, p == right, or left == right
	local d_py_ly = point.Y - left.Y
	local d_rx_lx = right.X - left.X
	local d_px_lx = point.X - left.X
	local d_ry_ly = right.Y - left.Y

	local dot = d_px_lx * d_rx_lx + d_py_ly * d_ry_ly
	-- if `dot` is 0, then `p` == `left` or `left` == `right` (reject)
	-- if `dot` is less than 0, then `p` is to the left of `left` (reject)
	if dot < self.eps then
		return false
	end

	local sqlen = d_rx_lx * d_rx_lx + d_ry_ly * d_ry_ly
	-- if `dot` > `sqlen`, then `p` is to the right of `right` (reject)
	-- therefore, if `dot - sqlen` is greater than 0, then `p` is to the right of `right` (reject)
	if dot - sqlen > -self.eps then
		return false
	end

	return true
end

function Epsilon:pointsSameX(p1: Point, p2: Point): boolean
	return math.abs(p1.X - p2.X) < self.eps
end

function Epsilon:pointsSameY(p1: Point, p2: Point): boolean
	return math.abs(p1.Y - p2.Y) < self.eps
end

function Epsilon:pointsSame(p1: Point, p2: Point): boolean
	return self:pointsSameX(p1, p2) and self:pointsSameY(p1, p2)
end

function Epsilon:pointsCompare(p1: Point, p2: Point): number
	-- returns -1 if p1 is smaller, 1 if p2 is smaller, 0 if equal
	if self:pointsSameX(p1, p2) then
		return iif(self:pointsSameY(p1, p2), 0, iif(p1.Y < p2.Y, -1, 1))
	end

	return iif(p1.X < p2.X, -1, 1)
end

function Epsilon:pointsCollinear(a: Point, b: Point, c: Point): boolean
	-- does pt1->pt2->pt3 make a straight line?
	-- essentially this is just checking to see if the slope(pt1->pt2) === slope(pt2->pt3)
	-- if slopes are equal, then they must be collinear, because they share pt2
	local dx1 = a.X - b.X
	local dy1 = a.Y - b.Y
	local dx2 = b.X - c.X
	local dy2 = b.Y - c.Y

	return math.abs(dx1 * dy2 - dx2 * dy1) < self.eps
end

function Epsilon:linesIntersect(a: Line, b: Line): (boolean, Intersection?)
	-- returns false if the lines are coincident (e.g., parallel or on top of each other)
	--
	-- returns an object if the lines intersect:
	--   {
	--     pt: [x, y],    where the intersection point is at
	--     alongA: where intersection point is along A,
	--     alongB: where intersection point is along B
	--   }
	--
	--  alongA and alongB will each be one of: -2, -1, 0, 1, 2
	--
	--  with the following meaning:
	--
	--    -2   intersection point is before segment's first point
	--    -1   intersection point is directly on segment's first point
	--     0   intersection point is between segment's first and second points (exclusive)
	--     1   intersection point is directly on segment's second point
	--     2   intersection point is after segment's second point
	local a0 = a.a
	local a1 = a.b
	local b0 = b.a
	local b1 = b.b
	local adx = a1.X - a0.X
	local ady = a1.Y - a0.Y
	local bdx = b1.X - b0.X
	local bdy = b1.Y - b0.Y

	local axb = adx * bdy - ady * bdx

	if math.abs(axb) < self.eps then
		return false, nil
	end

	local dx = a0.X - b0.X
	local dy = a0.Y - b0.Y

	local A = (bdx * dy - bdy * dx) / axb
	local B = (adx * dy - ady * dx) / axb

	local ret = {
		alongA = 0,
		alongB = 0,
		point = Vector2.new(a0.X + A * adx, a0.Y + A * ady),
	} :: Intersection

	-- categorize where intersection point is along A and B

	if A <= -self.eps then
		ret.alongA = -2
	elseif A < self.eps then
		ret.alongA = -1
	elseif A - 1 <= -self.eps then
		ret.alongA = 0
	elseif A - 1 < self.eps then
		ret.alongA = 1
	else
		ret.alongA = 2
	end

	if B <= -self.eps then
		ret.alongB = -2
	elseif B < self.eps then
		ret.alongB = -1
	elseif B - 1 <= -self.eps then
		ret.alongB = 0
	elseif B - 1 < self.eps then
		ret.alongB = 1
	else
		ret.alongB = 2
	end

	return true, ret
end

function Epsilon:pointInsideRegion(point: Point, region: Region): boolean
	local x = point.X
	local y = point.Y
	local last_x = region[#region].X
	local last_y = region[#region].Y
	local inside = false

	for i = 1, #region do
		local curr_x = region[i].X
		local curr_y = region[i].Y

		-- if y is between curr_y and last_y, and
		-- x is to the right of the boundary created by the line
		if
			(curr_y - y > self.eps) ~= (last_y - y > self.eps)
			and (last_x - curr_x) * (y - curr_y) / (last_y - curr_y) + curr_x - x > self.eps
		then
			inside = not inside
		end

		last_x = curr_x
		last_y = curr_y
	end

	return inside
end

return Epsilon
