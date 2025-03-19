--!strict

local function iif<T, U>(bool: boolean, a: T, b: U): T | U
	if bool then
		return a
	end

	return b
end

return iif
