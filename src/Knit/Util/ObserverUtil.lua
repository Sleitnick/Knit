-- ObserverUtil
-- Stephen Leitnick
-- March 03, 2021

--[[
	
	ObserverUtil.Compound(observers: {Observer}, handler: ({[child: string]: Instance}, maid: Maid) -> void): Maid
	
	Example:
	
		local observer1 = Observer.new(someModel, "SomeChild")
		local observer2 = Observer.new(anotherModel, "AnotherChild")
		
		ObserverUtil.Compound({observer1, observer2}, function(observers, maid)
			local someChild = observers[1].Instance
			local anotherChild = observers[2].Instance
			maid:GiveTask(function()
				-- Cleanup
			end)
		end)
	
--]]


local Maid = require(script.Parent.Maid)


local ObserverUtil = {}


function ObserverUtil.Compound(observers, handler)
	local compoundMaid = Maid.new()
	local observeAllMaid = Maid.new()
	local allAvailable = false
	local function Check()
		if (allAvailable) then return end
		for _,observer in ipairs(observers) do
			if (not observer.Instance) then
				return
			end
		end
		allAvailable = true
		handler(observers, observeAllMaid)
	end
	local function Cleanup()
		if (not allAvailable) then return end
		allAvailable = false
		observeAllMaid:DoCleaning()
	end
	for _,observer in ipairs(observers) do
		compoundMaid:GiveTask(observer:Observe(function(_child, maid)
			Check()
			maid:GiveTask(function()
				Cleanup()
			end)
		end))
	end
	compoundMaid:GiveTask(Cleanup)
	return compoundMaid
end


return ObserverUtil