local here = require("test_support").here

describe("here/1", function()
	it("works", function()
		assert.equal(
			"foo\nbar\n",
			here([[
				foo
				bar
			]])
		)
	end)
end)
