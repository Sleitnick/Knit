return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Symbol = require(Knit.Util.Symbol)

	describe("Constructor", function()

		it("should create a new symbol", function()
			local symbol = Symbol.new("Test")
			expect(Symbol.Is(symbol)).to.equal(true)
		end)

		it("should create a new symbol with a scope", function()
			local symbolScope = Symbol.new("Scope")
			local symbol = Symbol.new("Test", symbolScope)
			expect(Symbol.Is(symbol)).to.equal(true)
			expect(Symbol.IsInScope(symbol, symbolScope)).to.equal(true)
			expect(Symbol.IsInScope(symbolScope, symbol)).to.equal(false)
		end)

		it("should fail to create symbol without id", function()
			expect(function()
				Symbol.new()
			end).to.throw()
		end)

		it("should fail to create symbol with invalid scope", function()
			expect(function()
				Symbol.new("Test", "abc")
			end).to.throw()
		end)

	end)

end