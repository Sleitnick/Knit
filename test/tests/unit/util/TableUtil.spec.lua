return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local TableUtil = require(Knit.Util.TableUtil)

	describe("Copy", function()

		it("should create a table copy", function()
			local tbl = {a = {b = {c = {d = 32}}}}
			local tblCopy = TableUtil.Copy(tbl)
			expect(tbl).never.to.equal(tblCopy)
			expect(tbl.a).never.to.equal(tblCopy.a)
			expect(tblCopy.a.b.c.d).to.equal(tbl.a.b.c.d)
		end)

	end)

	describe("CopyShallow", function()

		it("should create a shallow dictionary copy", function()
			local tbl = {a = {b = {c = {d = 32}}}}
			local tblCopy = TableUtil.CopyShallow(tbl)
			expect(tblCopy).never.to.equal(tbl)
			expect(tblCopy.a).to.equal(tbl.a)
			expect(tblCopy.a.b.c.d).to.equal(tbl.a.b.c.d)
		end)

		it("should create a shallow array copy", function()
			local tbl = {10, 20, 30, 40}
			local tblCopy = TableUtil.CopyShallow(tbl)
			expect(tblCopy).never.to.equal(tbl)
			for i,v in ipairs(tbl) do
				expect(tblCopy[i]).to.equal(v)
			end
		end)

	end)

	describe("Sync", function()

		it("should sync tables", function()
			local template = {a = 32; b = 64; c = 128; e = {h = 1}}
			local tblSrc = {a = 32; b = 10; d = 1; e = {h = 2; n = 2}; f = {x = 10}}
			local tbl = TableUtil.Sync(tblSrc, template)
			expect(tbl.a).to.equal(template.a)
			expect(tbl.b).to.equal(10)
			expect(tbl.c).to.equal(template.c)
			expect(tbl.d).never.to.be.ok()
			expect(tbl.e.h).to.equal(2)
			expect(tbl.e.n).never.to.be.ok()
			expect(tbl.f).never.to.be.ok()
		end)

	end)

	describe("FastRemove", function()

		it("should swap remove index", function()
			local tbl = {1, 2, 3, 4, 5}
			TableUtil.FastRemove(tbl, 3)
			expect(#tbl).to.equal(4)
			expect(tbl[3]).to.equal(5)
		end)

	end)

	describe("FastRemoveFirstValue", function()

		it("should swap remove first value given", function()
			local tbl = {"hello", "world", "goodbye", "planet"}
			TableUtil.FastRemoveFirstValue(tbl, "world")
			expect(#tbl).to.equal(3)
			expect(tbl[2]).to.equal("planet")
		end)

	end)

	describe("Map", function()

		it("should map table", function()
			local tbl = {
				{FirstName = "John", LastName = "Doe"};
				{FirstName = "Jane", LastName = "Smith"};
			}
			local tblMapped = TableUtil.Map(tbl, function(person)
				return person.FirstName .. " " .. person.LastName
			end)
			expect(tblMapped[1]).to.equal("John Doe")
			expect(tblMapped[2]).to.equal("Jane Smith")
		end)

	end)

	describe("Filter", function()

		it("should filter table", function()
			local tbl = {10, 20, 30, 40, 50, 60, 70, 80, 90}
			local tblFiltered = TableUtil.Filter(tbl, function(n)
				return (n >= 30 and n <= 60)
			end)
			expect(#tblFiltered).to.equal(4)
			expect(tblFiltered[1]).to.equal(30)
			expect(tblFiltered[#tblFiltered]).to.equal(60)
		end)

	end)

	describe("Reduce", function()

		it("should reduce table with numbers", function()
			local tbl = {1, 2, 3, 4, 5}
			local reduced = TableUtil.Reduce(tbl, function(accum, value)
				return accum + value
			end)
			expect(reduced).to.equal(15)
		end)

		it("should reduce table", function()
			local tbl = {{Score = 10}, {Score = 20}, {Score = 30}}
			local reduced = TableUtil.Reduce(tbl, function(accum, value)
				return accum + value.Score
			end, 0)
			expect(reduced).to.equal(60)
		end)

		it("should reduce table with initial value", function()
			local tbl = {{Score = 10}, {Score = 20}, {Score = 30}}
			local reduced = TableUtil.Reduce(tbl, function(accum, value)
				return accum + (value.Score)
			end, 40)
			expect(reduced).to.equal(100)
		end)

		it("should reduce functions", function()
			local function Square(x) return x * x end
			local function Double(x) return x * 2 end
			local Func = TableUtil.Reduce({Square, Double}, function(a, b)
				return function(x)
					return a(b(x))
				end
			end)
			local result = Func(10)
			expect(result).to.equal(400)
		end)

	end)

	describe("Assign", function()

		it("should assign tables", function()
			local target = {a = 32; x = 100}
			local t1 = {b = 64; c = 128}
			local t2 = {a = 10; c = 100; d = 200}
			local tbl = TableUtil.Assign(target, t1, t2)
			expect(tbl.a).to.equal(10)
			expect(tbl.b).to.equal(64)
			expect(tbl.c).to.equal(100)
			expect(tbl.d).to.equal(200)
			expect(tbl.x).to.equal(100)
		end)

	end)

	describe("Extend", function()

		it("should extend tables", function()
			local tbl = {"a", "b", "c"}
			local extension = {"d", "e", "f"}
			local extended = TableUtil.Extend(tbl, extension)
			expect(table.concat(extended)).to.equal("abcdef")
		end)

	end)

	describe("Reverse", function()

		it("should create a table in reverse", function()
			local tbl = {1, 2, 3}
			local tblRev = TableUtil.Reverse(tbl)
			expect(table.concat(tblRev)).to.equal("321")
		end)

	end)

	describe("Shuffle", function()

		it("should shuffle a table", function()
			local tbl = {1, 2, 3, 4, 5}
			expect(function() TableUtil.Shuffle(tbl) end).never.to.throw()
		end)

	end)

	describe("Sample", function()

		it("should sample a table", function()
			local tbl = {1, 2, 3, 4, 5}
			local sample = TableUtil.Sample(tbl, 3)
			expect(#sample).to.equal(3)
		end)

	end)

	describe("Flat", function()

		it("should flatten table", function()
			local tbl = {1, 2, 3, {4, 5, {6, 7}}}
			local tblFlat = TableUtil.Flat(tbl, 3)
			expect(table.concat(tblFlat)).to.equal("1234567")
		end)

	end)

	describe("FlatMap", function()

		it("should map and flatten table", function()
			local tbl = {1, 2, 3, 4, 5, 6, 7}
			local tblFlat = TableUtil.FlatMap(tbl, function(n) return {n, n * 2} end)
			expect(table.concat(tblFlat)).to.equal("12243648510612714")
		end)

	end)

	describe("Keys", function()

		it("should give all keys of table", function()
			local tbl = {a = 1, b = 2, c = 3}
			local keys = TableUtil.Keys(tbl)
			expect(#keys).to.equal(3)
			expect(table.find(keys, "a")).to.be.ok()
			expect(table.find(keys, "b")).to.be.ok()
			expect(table.find(keys, "c")).to.be.ok()
		end)

	end)

	describe("Find", function()

		it("should find item in array", function()
			local tbl = {10, 20, 30}
			local item, index = TableUtil.Find(tbl, function(value)
				return (value == 20)
			end)
			expect(item).to.be.ok()
			expect(index).to.equal(2)
			expect(item).to.equal(20)
		end)

		it("should find item in dictionary", function()
			local tbl = {{Score = 10}, {Score = 20}, {Score = 30}}
			local item, index = TableUtil.Find(tbl, function(value)
				return (value.Score == 20)
			end)
			expect(item).to.be.ok()
			expect(index).to.equal(2)
			expect(item.Score).to.equal(20)
		end)

	end)

	describe("Every", function()

		it("should see every value is above 20", function()
			local tbl = {21, 40, 200}
			local every = TableUtil.Every(tbl, function(n)
				return (n > 20)
			end)
			expect(every).to.equal(true)
		end)

		it("should see every value is not above 20", function()
			local tbl = {20, 40, 200}
			local every = TableUtil.Every(tbl, function(n)
				return (n > 20)
			end)
			expect(every).never.to.equal(true)
		end)

	end)

	describe("Some", function()

		it("should see some value is above 20", function()
			local tbl = {5, 40, 1}
			local every = TableUtil.Some(tbl, function(n)
				return (n > 20)
			end)
			expect(every).to.equal(true)
		end)

		it("should see some value is not above 20", function()
			local tbl = {5, 15, 1}
			local every = TableUtil.Some(tbl, function(n)
				return (n > 20)
			end)
			expect(every).never.to.equal(true)
		end)

	end)

	describe("Truncate", function()

		it("should truncate an array", function()
			local t1 = {1, 2, 3, 4, 5}
			local t2 = TableUtil.Truncate(t1, 3)
			expect(#t2).to.equal(3)
			expect(t2[1]).to.equal(t1[1])
			expect(t2[2]).to.equal(t1[2])
			expect(t2[3]).to.equal(t1[3])
		end)
		
	end)

	describe("Zip", function()

		it("should zip arrays together", function()
			local t1 = {1, 2, 3, 4, 5}
			local t2 = {9, 8, 7, 6, 5}
			local t3 = {1, 1, 1, 1, 1}
			local lastIndex = 0
			for i,v in TableUtil.Zip(t1, t2, t3) do
				lastIndex = i
				expect(v[1]).to.equal(t1[i])
				expect(v[2]).to.equal(t2[i])
				expect(v[3]).to.equal(t3[i])
			end
			expect(lastIndex).to.equal(math.min(#t1, #t2, #t3))
		end)

		it("should zip arrays of different lengths together", function()
			local t1 = {1, 2, 3, 4, 5}
			local t2 = {9, 8, 7, 6}
			local t3 = {1, 1, 1}
			local lastIndex = 0
			for i,v in TableUtil.Zip(t1, t2, t3) do
				lastIndex = i
				expect(v[1]).to.equal(t1[i])
				expect(v[2]).to.equal(t2[i])
				expect(v[3]).to.equal(t3[i])
			end
			expect(lastIndex).to.equal(math.min(#t1, #t2, #t3))
		end)

		it("should zip maps together", function()
			local t1 = {a = 10, b = 20, c = 30}
			local t2 = {a = 100, b = 200, c = 300}
			local t3 = {a = 3000, b = 2000, c = 3000}
			for k,v in TableUtil.Zip(t1, t2, t3) do
				expect(v[1]).to.equal(t1[k])
				expect(v[2]).to.equal(t2[k])
				expect(v[3]).to.equal(t3[k])
			end
		end)

		it("should zip maps of different keys together", function()
			local t1 = {a = 10, b = 20, c = 30, d = 40}
			local t2 = {a = 100, b = 200, c = 300, z = 10}
			local t3 = {a = 3000, b = 2000, c = 3000, x = 0}
			for k,v in TableUtil.Zip(t1, t2, t3) do
				expect(v[1]).to.equal(t1[k])
				expect(v[2]).to.equal(t2[k])
				expect(v[3]).to.equal(t3[k])
			end
		end)

	end)

	describe("IsEmpty", function()

		it("should detect that table is empty", function()
			local tbl = {}
			local isEmpty = TableUtil.IsEmpty(tbl)
			expect(isEmpty).to.equal(true)
		end)

		it("should detect that array is not empty", function()
			local tbl = {10, 20, 30}
			local isEmpty = TableUtil.IsEmpty(tbl)
			expect(isEmpty).to.equal(false)
		end)

		it("should detect that dictionary is not empty", function()
			local tbl = {a = 10, b = 20, c = 30}
			local isEmpty = TableUtil.IsEmpty(tbl)
			expect(isEmpty).to.equal(false)
		end)

	end)

	describe("JSON", function()

		it("should encode json", function()
			local tbl = {hello = "world"}
			local json = TableUtil.EncodeJSON(tbl)
			expect(json).to.equal("{\"hello\":\"world\"}")
		end)

		it("should decode json", function()
			local json = "{\"hello\":\"world\"}"
			local tbl = TableUtil.DecodeJSON(json)
			expect(tbl).to.be.a("table")
			expect(tbl.hello).to.equal("world")
		end)

	end)

end