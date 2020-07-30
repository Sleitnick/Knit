return function()

	local Knit = require(script.Parent)
	local RemoteEvent = require(Knit.Util.Remote.RemoteEvent)
	local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)

	local IS_SERVER = game:GetService("RunService"):IsServer()

	if (IS_SERVER) then

		-- SERVER

		local MyService = Knit.CreateService { Name = "MyService" }
		local AnotherService = Knit.CreateService {
			Name = "AnotherService";
			ABC = 32;
			Client = {
				TestEvent = RemoteEvent.new();
				TestProp = RemoteProperty.new(10);
			}
		}

		function AnotherService:SomeMethod()
			return true
		end

		function AnotherService.Client:TestMethod(player, code)
			if (code == "xyz") then
				return "test"
			end
		end

		describe("knit server services", function()

			it("should create service", function()
				expect(MyService).to.be.a("table")
			end)

			it("should create a client table", function()
				expect(MyService.Client).to.be.a("table")
			end)

			it("should have a server table within client table", function()
				expect(MyService.Client.Server).to.equal(MyService)
			end)

			it("should allow services to be referenced", function()
				expect(Knit.Services.MyService).to.equal(MyService)
			end)

		end)

		describe("knit server misc", function()

			it("should know a service is a service", function()
				expect(Knit.IsService(Knit.Services.MyService)).to.equal(true)
			end)

			it("should know a normal table is not a service", function()
				expect(Knit.IsService({})).to.equal(false)
			end)

			it("should know a non-table is not a service", function()
				expect(Knit.IsService(true)).to.equal(false)
				expect(Knit.IsService(false)).to.equal(false)
				expect(Knit.IsService(nil)).to.equal(false)
				expect(Knit.IsService(1)).to.equal(false)
				expect(Knit.IsService(function() end)).to.equal(false)
				expect(Knit.IsService("str")).to.equal(false)
				expect(Knit.IsService(coroutine.create(function() end))).to.equal(false)
			end)

		end)

	else

		-- CLIENT

		describe("knit client controllers", function()

			local MyController = Knit.CreateController { Name = "MyController" }

			it("should create controller", function()
				expect(MyController).to.be.a("table")
			end)

			it("should allow controllers to be referenced", function()
				expect(Knit.Controllers.MyController).to.equal(MyController)
			end)

		end)

		describe("knit client services", function()

			local AnotherService = Knit.GetService("AnotherService")

			it("should reference server service", function()
				expect(AnotherService).to.be.a("table")
			end)

			it("should not expose server methods", function()
				expect(AnotherService.SomeMethod).never.to.be.ok()
			end)

			it("should not expose server props", function()
				expect(AnotherService.ABC).never.to.be.ok()
			end)

			it("should successfully call remote method", function()
				expect(AnotherService:TestMethod("xyz")).to.equal("test")
			end)

			it("should successfully call promisified remote method", function()
				local success, result = AnotherService:TestMethodPromise("xyz"):await()
				if (not success) then warn(result) end
				expect(success).to.equal(true)
				expect(result).to.equal("test")
			end)

			it("should successfully reference remote prop", function()
				expect(AnotherService.TestProp:Get()).to.equal(10)
			end)

		end)

		describe("knit client misc", function()

			it("should contain reference to local player", function()
				expect(Knit.Player).to.equal(game:GetService("Players").LocalPlayer)
			end)

		end)

	end

	-- SHARED

	describe("knit", function()

		it("should include version", function()
			local version = Knit.Version
			expect(type(version)).to.be.a("string")
		end)

		it("should successfully start", function()
			local success, err = Knit.Start():await()
			if (not success) then warn(err) end
			expect(success).to.equal(true)
		end)

		it("should fail if attempting to start after already started", function()
			local success = Knit.Start():await()
			expect(success).to.equal(false)
		end)

		it("should wait for start", function()
			local success = Knit.OnStart():await()
			expect(success).to.equal(true)
		end)

	end)

end