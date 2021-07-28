return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Janitor = require(Knit.Util.Janitor)
	local Promise = require(Knit.Util.Promise)

	describe("Constructor", function()

		local janitor

		beforeEach(function()
			janitor = Janitor.new()
		end)

		afterEach(function()
			janitor:Destroy()
		end)

		it("should track and clean up instances", function()
			local folder = Instance.new("Folder")
			folder.Parent = workspace
			janitor:Add(folder)
			expect(folder.Parent).to.equal(workspace)
			janitor:Cleanup()
			expect(folder.Parent).to.equal(nil)
		end)

		it("should track and clean up connections", function()
			local folder = Instance.new("Folder")
			local conn = folder.Changed:Connect(function() end)
			janitor:Add(conn)
			expect(conn.Connected).to.equal(true)
			janitor:Cleanup()
			expect(conn.Connected).to.equal(false)
		end)

		it("should track and fire functions", function()
			local value = 0
			janitor:Add(function()
				value = 1
			end)
			expect(value).to.equal(0)
			janitor:Cleanup()
			expect(value).to.equal(1)
		end)

		it("should track and cleanup custom method", function()
			local obj = {_destructed = false}
			function obj:Destruct()
				self._destructed = true
			end
			janitor:Add(obj, "Destruct")
			expect(obj._destructed).to.equal(false)
			janitor:Cleanup()
			expect(obj._destructed).to.equal(true)
		end)

		it("should link to an instance", function()
			local folder = Instance.new("Folder")
			folder.Parent = workspace
			local cleaned = false
			janitor:LinkToInstance(folder)
			janitor:Add(function()
				cleaned = true
			end)
			expect(cleaned).to.equal(false)
			folder:Destroy()
			task.wait()
			task.wait()
			expect(cleaned).to.equal(true)
		end)

		it("should cancel promise", function()
			local cancelled = false
			local promise = Promise.new(function(resolve, _reject, onCancel)
				onCancel(function()
					cancelled = true
				end)
				task.wait(100)
				resolve()
			end)
			janitor:AddPromise(promise)
			expect(cancelled).to.equal(false)
			janitor:Cleanup()
			expect(cancelled).to.equal(true)
		end)

	end)

end