

local Circles = {}

function Circles.computeRayForSlice(i, slices, center, radius)
	local step = (2 * math.pi) / slices
	local angle = i * step

	local edgePoint = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
	local lookAtCF = CFrame.lookAt(edgePoint, center)

	-- This matches your client: Hitbox.Position at edgePoint (approx) shooting inward
	local origin = edgePoint
	local direction = lookAtCF.LookVector * 100

	return origin, direction
end

return Circles