return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local TableUtil = require(Knit.Util.TableUtil)

	describe("TableUtil.Reverse", function()
		it("should create a table in reverse", function()
			local data = {1, 2, 3}
			expect(table.concat(TableUtil.Reverse(data))).to.equal("321")
		end)
	end)

end