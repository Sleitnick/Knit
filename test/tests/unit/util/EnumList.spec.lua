return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local EnumList = require(Knit.Util.EnumList)

	describe("Constructor", function()

		it("should create a new enumlist", function()
			expect(function()
				EnumList.new("Test", {"ABC", "XYZ"})
			end).never.to.throw()
		end)

		it("should fail to create a new enumlist with no name", function()
			expect(function()
				EnumList.new(nil, {"ABC", "XYZ"})
			end).to.throw()
		end)

	end)

	describe("Access", function()

		it("should be able to access enum items", function()
			local test = EnumList.new("Test", {"ABC", "XYZ"})
			expect(function()
				local _item = test.ABC
			end).never.to.throw()
			expect(test:Is(test.ABC)).to.equal(true)
		end)

		it("should throw if trying to access non-existing item", function()
			local test = EnumList.new("Test", {"ABC", "XYZ"})
			expect(function()
				local _item = test.Something
			end).to.throw()
		end)

	end)

end