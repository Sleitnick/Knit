return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Timer = require(Knit.Util.Timer)

	describe("Timer", function()

		local timer

		beforeEach(function()
			timer = Timer.new(0.1)
		end)

		afterEach(function()
			if (timer) then
				timer:Destroy()
				timer = nil
			end
		end)

		it("should create a new timer", function()
			expect(Timer.Is(timer)).to.equal(true)
		end)

		it("should tick appropriately", function()
			local start = time()
			timer:Start()
			timer.Tick:Wait()
			local duration = (time() - start)
			expect(duration).to.be.near(duration, 0.02)
		end)

		it("should start immediately", function()
			local start = time()
			local stop = nil
			timer.Tick:Connect(function()
				if (not stop) then
					stop = time()
				end
			end)
			timer:StartNow()
			timer.Tick:Wait()
			expect(stop).to.be.a("number")
			local duration = (stop - start)
			expect(duration).to.be.near(0, 0.02)
		end)

		it("should stop", function()
			local ticks = 0
			timer.Tick:Connect(function()
				ticks += 1
				print("TICK", ticks)
			end)
			timer:StartNow()
			timer:Stop()
			task.wait(1)
			expect(ticks).to.equal(1)
		end)

	end)

end
