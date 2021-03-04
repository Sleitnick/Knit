-- StreamableUtil
-- Stephen Leitnick
-- March 03, 2021

--[[
	
	StreamableUtil.Compound(observers: {Observer}, handler: ({[child: string]: Instance}, maid: Maid) -> void): Maid
	
	Example:
	
		local streamable1 = Streamable.new(someModel, "SomeChild")
		local streamable2 = Streamable.new(anotherModel, "AnotherChild")
		
		StreamableUtil.Compound({streamable1, streamable2}, function(streamables, maid)
			local someChild = streamables[1].Instance
			local anotherChild = streamables[2].Instance
			maid:GiveTask(function()
				-- Cleanup
			end)
		end)
	
--]]


local Maid = require(script.Parent.Maid)


local StreamableUtil = {}


function StreamableUtil.Compound(streamables, handler)
	local compoundMaid = Maid.new()
	local observeAllMaid = Maid.new()
	local allAvailable = false
	local function Check()
		if (allAvailable) then return end
		for _,streamable in pairs(streamables) do
			if (not streamable.Instance) then
				return
			end
		end
		allAvailable = true
		handler(streamables, observeAllMaid)
	end
	local function Cleanup()
		if (not allAvailable) then return end
		allAvailable = false
		observeAllMaid:DoCleaning()
	end
	for _,streamable in pairs(streamables) do
		compoundMaid:GiveTask(streamable:Observe(function(_child, maid)
			Check()
			maid:GiveTask(function()
				Cleanup()
			end)
		end))
	end
	compoundMaid:GiveTask(Cleanup)
	return compoundMaid
end


return StreamableUtil