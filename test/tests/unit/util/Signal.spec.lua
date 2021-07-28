local function AwaitCondition(predicate, timeout)
	local start = os.clock()
	timeout = (timeout or 10)
	while (true) do
		if (predicate()) then return true end
		if ((os.clock() - start) > timeout) then return false end
		task.wait()
	end
end

return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Signal = require(Knit.Util.Signal)
	local Janitor = require(Knit.Util.Janitor)

	describe("Constructor", function()

		it("should create a new signal and fire it", function()
			local signal = Signal.new()
			expect(Signal.Is(signal)).to.equal(true)
			task.defer(function()
				signal:Fire(10, 20)
			end)
			local n1, n2 = signal:Wait()
			expect(n1).to.equal(10)
			expect(n2).to.equal(20)
			signal:Destroy()
		end)

		it("should create a new signal and clean it up with a janitor", function()
			local janitor = Janitor.new()
			local signal = Signal.new(janitor)
			expect(Signal.Is(signal)).to.equal(true)
			signal:Connect(function() end)
			expect(#signal:_getConnections()).to.equal(1)
			janitor:Destroy()
			expect(#signal:_getConnections()).to.equal(0)
			signal:Destroy()
		end)

		it("should create a proxy signal and connect to it", function()
			local signal = Signal.Wrap(game:GetService("RunService").Heartbeat)
			expect(Signal.Is(signal)).to.equal(true)
			local fired = false
			signal:Connect(function()
				fired = true
			end)
			expect(AwaitCondition(function() return fired end, 2)).to.equal(true)
			signal:Destroy()
		end)

	end)

	describe("Fire", function()

		it("should be able to fire primitive argument", function()
			local signal = Signal.new()
			local send = 10
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:Fire(send)
			expect(AwaitCondition(function() return (send == value) end, 1)).to.equal(true)
			signal:Destroy()
		end)

		it("should be able to fire a reference based argument", function()
			local signal = Signal.new()
			local send = {10, 20}
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:Fire(send)
			expect(AwaitCondition(function() return (send == value) end, 1)).to.equal(true)
			signal:Destroy()
		end)

	end)

	describe("Wait", function()

		it("should be able to wait for a signal to fire", function()
			local signal = Signal.new()
			task.defer(function()
				signal:Fire(10, 20, 30)
			end)
			local n1, n2, n3 = signal:Wait()
			expect(n1).to.equal(10)
			expect(n2).to.equal(20)
			expect(n3).to.equal(30)
			signal:Destroy()
		end)

	end)

	describe("Await", function()

		it("should wait for a signal using a promise", function()
			local signal = Signal.new()
			task.defer(function()
				signal:Fire(50, 80, 100)
			end)
			local success, n1, n2, n3 = signal:Await():Await()
			expect(success).to.equal(true)
			expect(n1).to.equal(50)
			expect(n2).to.equal(80)
			expect(n3).to.equal(100)
			signal:Destroy()
		end)

	end)

	describe("DisconnectAll", function()

		it("should disconnect all connections", function()
			local signal = Signal.new()
			local con1 = signal:Connect(function() end)
			local con2 = signal:Connect(function() end)
			expect(#signal:_getConnections()).to.equal(2)
			expect(con1.Connected).to.equal(true)
			expect(con2.Connected).to.equal(true)
			signal:DisconnectAll()
			expect(#signal:_getConnections()).to.equal(0)
			expect(con1.Connected).to.equal(false)
			expect(con2.Connected).to.equal(false)
			signal:Destroy()
		end)

	end)

	describe("Disconnect", function()

		it("should disconnect connection", function()
			local signal = Signal.new()
			local con = signal:Connect(function() end)
			expect(#signal:_getConnections()).to.equal(1)
			expect(con.Connected).to.equal(true)
			con:Disconnect()
			expect(#signal:_getConnections()).to.equal(0)
			expect(con.Connected).to.equal(false)
			signal:Destroy()
		end)

	end)

end