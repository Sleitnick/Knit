return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Ser = require(Knit.Util.Ser)
	local Option = require(Knit.Util.Option)

	describe("SerializeArgs", function()
		it("should serialize an option", function()
			local opt = Option.Some(32)
			local serOpt = table.unpack(Ser.SerializeArgs(opt))
			expect(serOpt.ClassName).to.equal("Option")
			expect(serOpt.Value).to.equal(32)
		end)
	end)

	describe("SerializeArgsAndUnpack", function()
		it("should serialize an option", function()
			local opt = Option.Some(32)
			local serOpt = Ser.SerializeArgsAndUnpack(opt)
			expect(serOpt.ClassName).to.equal("Option")
			expect(serOpt.Value).to.equal(32)
		end)
	end)

	describe("DeserializeArgs", function()
		it("should deserialize args to option", function()
			local serOpt = {
				ClassName = "Option";
				Value = 32;
			}
			local opt = table.unpack(Ser.DeserializeArgs(serOpt))
			expect(Option.Is(opt)).to.equal(true)
			expect(opt:Contains(32)).to.equal(true)
		end)
	end)

	describe("DeserializeArgsAndUnpack", function()
		it("should deserialize args to option", function()
			local serOpt = {
				ClassName = "Option";
				Value = 32;
			}
			local opt = Ser.DeserializeArgsAndUnpack(serOpt)
			expect(Option.Is(opt)).to.equal(true)
			expect(opt:Contains(32)).to.equal(true)
		end)
	end)

end