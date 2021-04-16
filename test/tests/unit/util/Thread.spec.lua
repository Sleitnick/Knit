local function AwaitCondition(predicate, timeout)
	local start = os.clock()
	timeout = (timeout or 10)
	while (true) do
		if (predicate()) then return true end
		if ((os.clock() - start) > timeout) then return false end
		wait()
	end
end

return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Thread = require(Knit.Util.Thread)

	describe("SpawnNow", function()

		it("should spawn now and pass arguments", function()
			local x, y, z
			Thread.SpawnNow(function(a, b, c)
				x, y, z = a, b, c
			end, 1, 2, 3)
			expect(x).to.equal(1)
			expect(y).to.equal(2)
			expect(z).to.equal(3)
		end)

	end)

	describe("Spawn", function()

		it("should spawn and pass arguments", function()
			local x, y, z
			local done = false
			Thread.Spawn(function(a, b, c)
				x, y, z = a, b, c
				done = true
			end, 1, 2, 3)
			expect(AwaitCondition(function()
				return done
			end, 1)).to.equal(true)
			expect(x).to.equal(1)
			expect(y).to.equal(2)
			expect(z).to.equal(3)
		end)

		it("should cancel spawn", function()
			local done = false
			local handle = Thread.Spawn(function()
				done = true
			end)
			handle:Disconnect()
			expect(AwaitCondition(function()
				return done
			end, 0.1)).to.equal(false)
		end)

	end)

	describe("Delay", function()

		it("should delay before firing function", function()
			local x, y, z
			local done = false
			local start = os.clock()
			local stop
			local delayTime = 0.1
			Thread.Delay(delayTime, function(a, b, c)
				x, y, z = a, b, c
				stop = os.clock()
				done = true
			end, 1, 2, 3)
			expect(AwaitCondition(function()
				return done
			end, 1)).to.equal(true)
			expect((stop - start) >= delayTime)
			expect(x).to.equal(1)
			expect(y).to.equal(2)
			expect(z).to.equal(3)
		end)

		it("should cancel delay", function()
			local done = false
			local handle = Thread.Delay(0.1, function()
				done = true
			end)
			handle:Disconnect()
			expect(AwaitCondition(function()
				return done
			end, 0.2)).to.equal(false)
		end)

	end)

	describe("DelayRepeat", function()

		it("should repeatedly delay", function()
			local itr = 0
			local handle = Thread.DelayRepeat(0.1, function()
				itr += 1
			end)
			expect(AwaitCondition(function()
				return (itr >= 3)
			end, 1)).to.equal(true)
			handle:Disconnect()
		end)

		it("should repeatedly delay and start immediately", function()
			local itr = 0
			local handle = Thread.DelayRepeat(0.1, function()
				itr += 1
			end, Thread.DelayRepeatBehavior.Immediate)
			expect(AwaitCondition(function()
				return (itr >= 3)
			end, 1)).to.equal(true)
			handle:Disconnect()
		end)

	end)

end