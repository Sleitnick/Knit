-- StreamableUtil
-- Stephen Leitnick
-- March 03, 2021

--[[

	StreamableUtil.Compound(observers: {Observer}, handler: ({[child: string]: Instance}, janitor: Janitor) -> void): Janitor

	Example:

		local streamable1 = Streamable.new(someModel, "SomeChild")
		local streamable2 = Streamable.new(anotherModel, "AnotherChild")

		StreamableUtil.Compound({S1 = streamable1, S2 = streamable2}, function(streamables, janitor)
			local someChild = streamables.S1.Instance
			local anotherChild = streamables.S2.Instance
			janitor:Add(function()
				-- Cleanup
			end)
		end)

--]]


local Janitor = require(script.Parent.Janitor)


local StreamableUtil = {}


function StreamableUtil.Compound(streamables, handler)
	local compoundJanitor = Janitor.new()
	local observeAllJanitor = Janitor.new()
	local allAvailable = false
	local function Check()
		if (allAvailable) then return end
		for _,streamable in pairs(streamables) do
			if (not streamable.Instance) then
				return
			end
		end
		allAvailable = true
		handler(streamables, observeAllJanitor)
	end
	local function Cleanup()
		if (not allAvailable) then return end
		allAvailable = false
		observeAllJanitor:Cleanup()
	end
	for _,streamable in pairs(streamables) do
		compoundJanitor:Add(streamable:Observe(function(_child, janitor)
			Check()
			janitor:GiveTask(Cleanup)
		end))
	end
	compoundJanitor:GiveTask(Cleanup)
	return compoundJanitor
end


return StreamableUtil