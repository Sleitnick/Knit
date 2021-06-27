return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Component = require(Knit.Util.Component)
	local Maid = require(Knit.Util.Maid)
	local Promise = require(Knit.Util.Promise)

	local CollectionService = game:GetService("CollectionService")

	local TAG = "__KnitTestComponent__"

	local taggedInstanceFolder

	local function CreateTaggedInstance()
		local folder = Instance.new("Folder")
		CollectionService:AddTag(folder, TAG)
		folder.Name = "ComponentTest"
		folder.Archivable = false
		folder.Parent = taggedInstanceFolder
		return folder
	end

	local TestComponentMain = {}
	TestComponentMain.__index = TestComponentMain
	TestComponentMain.Tag = TAG
	function TestComponentMain.new(_instance)
		local self = setmetatable({}, TestComponentMain)
		self._maid = Maid.new()
		return self
	end
	function TestComponentMain:HeartbeatUpdate()
		self.DidHeartbeatUpdate = true
	end
	function TestComponentMain:SteppedUpdate()
		self.DidSteppedUpdate = true
	end
	function TestComponentMain:RenderUpdate()
		self.DidRenderUpdate = true
	end
	function TestComponentMain:Init()
		self.DidInit = true
	end
	function TestComponentMain:Deinit()
		self.DidDeinit = true
	end
	function TestComponentMain:Destroy()
		self._maid:Destroy()
	end

	beforeAll(function()
		Component.new(TAG, TestComponentMain)
		taggedInstanceFolder = Instance.new("Folder")
		taggedInstanceFolder.Name = "KnitComponentTest"
		taggedInstanceFolder.Archivable = false
		taggedInstanceFolder.Parent = workspace
	end)

	afterEach(function()
		taggedInstanceFolder:ClearAllChildren()
	end)

	afterAll(function()
		taggedInstanceFolder:Destroy()
	end)

	describe("Component", function()

		it("should be able to get component from tag", function()
			local TestComponent = Component.FromTag(TAG)
			expect(TestComponent).to.be.ok()
		end)

		it("should create and remove a component", function()
			local TestComponent = Component.FromTag(TAG)
			local instance = CreateTaggedInstance()
			wait()
			local all = TestComponent:GetAll()
			wait()
			expect(#all).to.equal(1)
			expect(all[1].Instance).to.equal(instance)
			instance:Destroy()
			wait()
			all = TestComponent:GetAll()
			expect(#all).to.equal(0)
		end)

		it("should get component from instance", function()
			local TestComponent = Component.FromTag(TAG)
			local instance = CreateTaggedInstance()
			wait()
			expect(TestComponent:GetFromInstance(instance)).to.be.ok()
		end)

		it("should get component from ID", function()
			local TestComponent = Component.FromTag(TAG)
			local instance = CreateTaggedInstance()
			wait()
			local id = instance:GetAttribute("ComponentServerId")
			expect(TestComponent:GetFromID(id)).to.be.ok()
		end)

		it("should filter", function()
			local TestComponent = Component.FromTag(TAG)
			for i = 1,10 do
				local instance = CreateTaggedInstance()
				instance:SetAttribute("SomeNumber", i)
			end
			wait()
			local aboveFive = TestComponent:Filter(function(component)
				return component.Instance:GetAttribute("SomeNumber") > 5
			end)
			expect(#aboveFive).to.equal(5)
		end)

		it("should wait for component by instance", function()
			local TestComponent = Component.FromTag(TAG)
			local instance = CreateTaggedInstance()
			local success, obj = TestComponent:WaitFor(instance):Await()
			expect(success).to.equal(true)
			expect(obj).to.be.ok()
		end)

		it("should wait for component by name", function()
			local TestComponent = Component.FromTag(TAG)
			local instance = CreateTaggedInstance()
			instance.Name = "SomeUniqueInstanceNameForKnitTest"
			local success, obj = TestComponent:WaitFor(instance.Name):Await()
			expect(success).to.equal(true)
			expect(obj).to.be.ok()
		end)

		it("should run all runtime updates", function()
			local TestComponent = Component.FromTag(TAG)
			local instance = CreateTaggedInstance()
			local success, obj = TestComponent:WaitFor(instance):Await()
			expect(success).to.equal(true)
			local runtimeSuccess = Promise.new(function(resolve, _reject, onCancel)
				local handle
				handle = game:GetService("RunService").Heartbeat:Connect(function()
					if (obj.DidHeartbeatUpdate and obj.DidSteppedUpdate and obj.DidRenderUpdate) then
						resolve()
					end
				end)
				onCancel(function() handle:Disconnect() end)
			end):Timeout(5):Await()
			expect(runtimeSuccess).to.equal(true)
		end)

		it("should run init and deinit methods", function()
			local TestComponent = Component.FromTag(TAG)
			local instance = CreateTaggedInstance()
			local success, obj = TestComponent:WaitFor(instance):Await()
			expect(success).to.equal(true)
			local initDeinitSuccess = Promise.new(function(resolve, _reject, onCancel)
				local handle
				handle = game:GetService("RunService").Heartbeat:Connect(function()
					if (obj.DidDeinit) then
						resolve()
					elseif (obj.DidInit and instance.Parent) then
						instance:Destroy()
					end
				end)
				onCancel(function() handle:Disconnect() end)
			end):Timeout(5):Await()
			expect(initDeinitSuccess).to.equal(true)
		end)

	end)

end