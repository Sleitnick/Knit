return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Option = require(Knit.Util.Option)

	describe("Some", function()

		it("should create some option", function()
			local opt = Option.Some(true)
			expect(opt:IsSome()).to.equal(true)
		end)

		it("should fail to create some option with nil", function()
			expect(function()
				Option.Some(nil)
			end).to.throw()
		end)

		it("should not be none", function()
			local opt = Option.Some(10)
			expect(opt:IsNone()).to.equal(false)
		end)

	end)

	describe("None", function()

		it("should be able to reference none", function()
			expect(function()
				local _none = Option.None
			end).never.to.throw()
		end)

		it("should be able to check if none", function()
			local none = Option.None
			expect(none:IsNone()).to.equal(true)
		end)

		it("should be able to check if not some", function()
			local none = Option.None
			expect(none:IsSome()).to.equal(false)
		end)

	end)

	describe("Equality", function()

		it("should equal the same some from same options", function()
			local opt = Option.Some(32)
			expect(opt).to.equal(opt)
		end)

		it("should equal the same some from different options", function()
			local opt1 = Option.Some(32)
			local opt2 = Option.Some(32)
			expect(opt1).to.equal(opt2)
		end)

	end)

	describe("Assert", function()

		it("should assert that a some option is an option", function()
			expect(Option.Is(Option.Some(10))).to.equal(true)
		end)

		it("should assert that a none option is an option", function()
			expect(Option.Is(Option.None)).to.equal(true)
		end)

		it("should assert that a non-option is not an option", function()
			expect(Option.Is(10)).to.equal(false)
			expect(Option.Is(true)).to.equal(false)
			expect(Option.Is(false)).to.equal(false)
			expect(Option.Is("Test")).to.equal(false)
			expect(Option.Is({})).to.equal(false)
			expect(Option.Is(function() end)).to.equal(false)
			expect(Option.Is(coroutine.create(function() end))).to.equal(false)
			expect(Option.Is(Option)).to.equal(false)
		end)

	end)

	describe("Unwrap", function()

		it("should unwrap a some option", function()
			local opt = Option.Some(10)
			expect(function()
				opt:Unwrap()
			end).never.to.throw()
			expect(opt:Unwrap()).to.equal(10)
		end)

		it("should fail to unwrap a none option", function()
			local opt = Option.None
			expect(function()
				opt:Unwrap()
			end).to.throw()
		end)

	end)

	describe("Expect", function()

		it("should expect a some option", function()
			local opt = Option.Some(10)
			expect(function()
				opt:Expect("Expecting some value")
			end).never.to.throw()
			expect(opt:Unwrap()).to.equal(10)
		end)

		it("should fail when expecting on a none option", function()
			local opt = Option.None
			expect(function()
				opt:Expect("Expecting some value")
			end).to.throw()
		end)

	end)

	describe("ExpectNone", function()

		it("should fail to expect a none option", function()
			local opt = Option.Some(10)
			expect(function()
				opt:ExpectNone("Expecting some value")
			end).to.throw()
		end)

		it("should expect a none option", function()
			local opt = Option.None
			expect(function()
				opt:ExpectNone("Expecting some value")
			end).never.to.throw()
		end)

	end)

	describe("UnwrapOr", function()

		it("should unwrap a some option", function()
			local opt = Option.Some(10)
			expect(opt:UnwrapOr(20)).to.equal(10)
		end)

		it("should unwrap a none option", function()
			local opt = Option.None
			expect(opt:UnwrapOr(20)).to.equal(20)
		end)

	end)

	describe("UnwrapOrElse", function()

		it("should unwrap a some option", function()
			local opt = Option.Some(10)
			local result = opt:UnwrapOrElse(function() return 30 end)
			expect(result).to.equal(10)
		end)

		it("should unwrap a none option", function()
			local opt = Option.None
			local result = opt:UnwrapOrElse(function() return 30 end)
			expect(result).to.equal(30)
		end)

	end)

	describe("And", function()

		it("should return the second option with and when both are some", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.Some(2)
			expect(opt1:And(opt2)).to.equal(opt2)
		end)

		it("should return none when first option is some and second option is none", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.None
			expect(opt1:And(opt2):IsNone()).to.equal(true)
		end)

		it("should return none when first option is none and second option is some", function()
			local opt1 = Option.None
			local opt2 = Option.Some(2)
			expect(opt1:And(opt2):IsNone()).to.equal(true)
		end)

		it("should return none when both options are none", function()
			local opt1 = Option.None
			local opt2 = Option.None
			expect(opt1:And(opt2):IsNone()).to.equal(true)
		end)

	end)

	describe("AndThen", function()

		it("should pass the some value to the predicate", function()
			local opt = Option.Some(32)
			opt:AndThen(function(value)
				expect(value).to.equal(32)
				return Option.None
			end)
		end)

		it("should throw if an option is not returned from predicate", function()
			local opt = Option.Some(32)
			expect(function()
				opt:AndThen(function()
				end)
			end).to.throw()
		end)

		it("should return none if the option is none", function()
			local opt = Option.None
			expect(opt:AndThen(function()
				return Option.Some(10)
			end):IsNone()).to.equal(true)
		end)

		it("should return option of predicate if option is some", function()
			local opt = Option.Some(32)
			local result = opt:AndThen(function()
				return Option.Some(10)
			end)
			expect(result:IsSome()).to.equal(true)
			expect(result:Unwrap()).to.equal(10)
		end)

	end)

	describe("Or", function()

		it("should return the first option if it is some", function()
			local opt1 = Option.Some(10)
			local opt2 = Option.Some(20)
			expect(opt1:Or(opt2)).to.equal(opt1)
		end)

		it("should return the second option if the first one is none", function()
			local opt1 = Option.None
			local opt2 = Option.Some(20)
			expect(opt1:Or(opt2)).to.equal(opt2)
		end)

	end)

	describe("OrElse", function()

		it("should return the first option if it is some", function()
			local opt1 = Option.Some(10)
			local opt2 = Option.Some(20)
			expect(opt1:OrElse(function() return opt2 end)).to.equal(opt1)
		end)

		it("should return the second option if the first one is none", function()
			local opt1 = Option.None
			local opt2 = Option.Some(20)
			expect(opt1:OrElse(function() return opt2 end)).to.equal(opt2)
		end)

		it("should throw if the predicate does not return an option", function()
			local opt1 = Option.None
			expect(function() opt1:OrElse(function() end) end).to.throw()
		end)

	end)

	describe("XOr", function()

		it("should return first option if first option is some and second option is none", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.None
			expect(opt1:XOr(opt2)).to.equal(opt1)
		end)

		it("should return second option if first option is none and second option is some", function()
			local opt1 = Option.None
			local opt2 = Option.Some(2)
			expect(opt1:XOr(opt2)).to.equal(opt2)
		end)

		it("should return none if first and second option are some", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.Some(2)
			expect(opt1:XOr(opt2)).to.equal(Option.None)
		end)

		it("should return none if first and second option are none", function()
			local opt1 = Option.None
			local opt2 = Option.None
			expect(opt1:XOr(opt2)).to.equal(Option.None)
		end)

	end)

	describe("Filter", function()

		it("should return none if option is none", function()
			local opt = Option.None
			expect(opt:Filter(function() end)).to.equal(Option.None)
		end)

		it("should return none if option is some but fails predicate", function()
			local opt = Option.Some(10)
			expect(opt:Filter(function(_v) return false end)).to.equal(Option.None)
		end)

		it("should return self if option is some and passes predicate", function()
			local opt = Option.Some(10)
			expect(opt:Filter(function(_v) return true end)).to.equal(opt)
		end)

	end)

	describe("Contains", function()

		it("should return true if some option contains the given value", function()
			local opt = Option.Some(32)
			expect(opt:Contains(32)).to.equal(true)
		end)

		it("should return false if some option does not contain the given value", function()
			local opt = Option.Some(32)
			expect(opt:Contains(64)).to.equal(false)
		end)

		it("should return false if option is none", function()
			local opt = Option.None
			expect(opt:Contains(64)).to.equal(false)
		end)

	end)

	describe("ToString", function()

		it("should return string of none option", function()
			local opt = Option.None
			expect(tostring(opt)).to.equal("Option<None>")
		end)

		it("should return string of some option with type", function()
			local values = {10, true, false, "test", {}, function() end, coroutine.create(function() end), workspace}
			for _,value in ipairs(values) do
				local expectedString = ("Option<%s>"):format(typeof(value))
				expect(tostring(Option.Some(value))).to.equal(expectedString)
			end
		end)

	end)

end