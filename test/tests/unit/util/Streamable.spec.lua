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
			streamable:Observe(function(_instance, janitor)
				observed += 1
				janitor:Add(function()
					cleaned += 1
				end)
			end)
			wait()
			testInstance.Parent = nil
			wait()
			testInstance.Parent = instanceFolder
			wait()
			streamable:Destroy()
			wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)

		it("should detect instance that is not immediately available", function()
			local streamable = Streamable.new(instanceFolder, "TestImmediate")
			local observed = 0
			local cleaned = 0
			streamable:Observe(function(_instance, janitor)
				observed += 1
				janitor:Add(function()
					cleaned += 1
				end)
			end)
			wait(0.1)
			local testInstance = CreateInstance("TestImmediate")
			wait()
			testInstance.Parent = nil
			wait()
			testInstance.Parent = instanceFolder
			wait()
			streamable:Destroy()
			wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)

	end)

end