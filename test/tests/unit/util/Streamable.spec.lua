return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Streamable = require(Knit.Util.Streamable)

	local instanceFolder

	local function CreateInstance(name)
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Archivable = false
		folder.Parent = instanceFolder
		return folder
	end

	beforeAll(function()
		instanceFolder = Instance.new("Folder")
		instanceFolder.Name = "KnitTest"
		instanceFolder.Archivable = false
		instanceFolder.Parent = workspace
	end)

	afterEach(function()
		instanceFolder:ClearAllChildren()
	end)

	afterAll(function()
		instanceFolder:Destroy()
	end)

	describe("Streamable", function()

		it("should detect instance that is immediately available", function()
			local testInstance = CreateInstance("TestImmediate")
			local streamable = Streamable.new(instanceFolder, "TestImmediate")
			local observed = 0
			local cleaned = 0
			streamable:Observe(function(_instance, maid)
				observed += 1
				maid:GiveTask(function()
					cleaned += 1
				end)
			end)
			task.wait()
			testInstance.Parent = nil
			task.wait()
			testInstance.Parent = instanceFolder
			task.wait()
			streamable:Destroy()
			task.wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)

		it("should detect instance that is not immediately available", function()
			local streamable = Streamable.new(instanceFolder, "TestImmediate")
			local observed = 0
			local cleaned = 0
			streamable:Observe(function(_instance, maid)
				observed += 1
				maid:GiveTask(function()
					cleaned += 1
				end)
			end)
			task.wait(0.1)
			local testInstance = CreateInstance("TestImmediate")
			task.wait()
			testInstance.Parent = nil
			task.wait()
			testInstance.Parent = instanceFolder
			task.wait()
			streamable:Destroy()
			task.wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)

	end)

end