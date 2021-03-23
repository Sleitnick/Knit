-- Loader
-- Stephen Leitnick
-- January 10, 2021

--[[

	Loads all ModuleScripts within the given parent.

	Loader.LoadChildren(parent: Instance): module[]
	Loader.LoadDescendants(parent: Instance): module[]

--]]


local Loader = {}


function Loader.LoadChildren(parent)
	local modules = {}
	local n = 0
	for _,child in ipairs(parent:GetChildren()) do
		if (child:IsA("ModuleScript")) then
			local m = require(child)
			n += 1
			modules[n] = m
		end
	end
	return modules
end


function Loader.LoadDescendants(parent)
	local modules = {}
	local n = 0
	for _,descendant in ipairs(parent:GetDescendants()) do
		if (descendant:IsA("ModuleScript")) then
			local m = require(descendant)
			n += 1
			modules[n] = m
		end
	end
	return modules
end


return Loader
