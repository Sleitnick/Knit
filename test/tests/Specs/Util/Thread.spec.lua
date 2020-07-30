return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Thread = require(Knit.Util.Thread)

	describe("thread", function()

		it("should spawn now", function()
			local done = Instance.new("BindableEvent")
			local testArg = 10
			expect(function()
				Thread.SpawnNow(function(n)
					done:Fire(n)
				end, testArg)
			end).never.to.throw()
			local returnArg = done.Event:Wait()
			done:Destroy()
			expect(returnArg).to.equal(testArg)
		end)

		it("should spawn", function()
			expect(Thread.Spawn).never.to.throw()
		end)

		it("should delay", function()
			expect(Thread.Delay, 0).never.to.throw()
		end)

	end)

end