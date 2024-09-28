local here = require("test_support").here
local parser = require("nvim-kitty.parsers").wrap(require("nvim-kitty.parsers.generic"))

it("can extract arbitrary paths", function()
	local corpus = here([[
			error[E0308]: mismatched types
				 --> src/parser.rs:716:21
					|
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 21,
			lnum = 716,
			path = "src/parser.rs",
		},
	}, r)
end)

it("can extract paths from the middle of a string", function()
	local corpus = here([[
			abc abc src/parser.rs:716:21 abc abc
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 21,
			lnum = 716,
			path = "src/parser.rs",
		},
	}, r)
end)

it("can extract paths at the start of a line", function()
	local corpus = here([[
			src/parser.rs:716:21 abc abc
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 21,
			lnum = 716,
			path = "src/parser.rs",
		},
	}, r)
end)

it("can extract paths at the end of a line", function()
	local corpus = here([[
			abc abc src/parser.rs:716:21
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 21,
			lnum = 716,
			path = "src/parser.rs",
		},
	}, r)
end)

pending("can extract paths enclosed in brackets", function()
	local corpus = here([[
			[src/parser.rs:716:21]
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 21,
			lnum = 716,
			path = "src/parser.rs",
		},
	}, r)
end)
