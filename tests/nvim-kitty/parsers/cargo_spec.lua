local t = require("test_support")
local parser = require("nvim-kitty.parsers").wrap(require("nvim-kitty.parsers.cargo"))

it("processes cargo errors", function()
	local corpus = t.here([[
			error[E0308]: mismatched types
				 --> src/parser.rs:716:21
					|
			716 |                     key,
					|                     ^^^ expected `ObjectPropertyKey<'_>`, found `String`
					|
			help: try wrapping the expression in `ast::ObjectPropertyKey::Key`
					|
			716 |                     key: ast::ObjectPropertyKey::Key(key),
					|                     +++++++++++++++++++++++++++++++++   +
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 21,
			lnum = 716,
			path = "src/parser.rs",
			severity = vim.diagnostic.severity.ERROR,
			text = "mismatched types",
		},
	}, r)
end)

it("processes cargo warnings", function()
	local corpus = t.here([[
		warning: unreachable pattern
				--> src/ast.rs:1147:13
				 |
		1147 |             Ast::CondExpr { .. } => todo!(),
				 |             ^^^^^^^^^^^^^^^^^^^^
				 |
				 = note: `#[warn(unreachable_patterns)]` on by default
			
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 13,
			lnum = 1147,
			path = "src/ast.rs",
			severity = vim.diagnostic.severity.WARN,
			text = "unreachable pattern",
		},
	}, r)
end)
