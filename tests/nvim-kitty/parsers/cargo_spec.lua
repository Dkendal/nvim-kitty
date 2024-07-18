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

it("processes todo panics", function()
	local corpus = t.here([[
		thread 'parser::parser_tests::object_literal::index' panicked at src/parser.rs:708:25:
		not yet implemented
		note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 25,
			lnum = 708,
			path = "src/parser.rs",
			severity = vim.diagnostic.severity.ERROR,
			text = "not yet implemented",
		},
	}, r)
end)

it("processes rust backtraces", function()
	local corpus = t.here([[
		thread 'parser::parser_tests::match_ts' panicked at src/parser.rs:2118:9:
			--> 45:15
			 |
		45 |     readonly [__kind__]: Label,
			 |               ^---
			 |
			 = expected index_property_key
		stack backtrace:
			 0: rust_begin_unwind
								 at /rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/std/src/panicking.rs:658:5
			 1: core::panicking::panic_fmt
								 at /rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/panicking.rs:74:14
		note: Some details are omitted, run with `RUST_BACKTRACE=full` for a verbose backtrace.
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 9,
			lnum = 2118,
			path = "src/parser.rs",
			severity = 1,
			text = "--> 45:15",
		},
		{
			col = 5,
			lnum = 658,
			path = "/rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/std/src/panicking.rs",
			severity = 1,
			stack_number = "0",
			text = "0: rust_begin_unwind\n",
		},
		{
			col = 14,
			lnum = 74,
			path = "/rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/panicking.rs",
			severity = 1,
			stack_number = "1",
			text = "1: core::panicking::panic_fmt\n",
		},
	}, r)
end)

it("processes dbg output", function()
	local corpus = t.here([[
		[src/runtime.rs:38:9] ast.eval() = Node {
				span: Some(
						Span {
								str: "1",
								start: 18,
								end: 19,
						},
				),
				value: Number(
						"1",
				),
		}
		thread 'runtime::tests::unquote' panicked at src/runtime.rs:40:9:
		explicit panic
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{
			col = 9,
			lnum = 38,
			path = "src/runtime.rs",
			severity = vim.diagnostic.severity.INFO,
			text = "dbg: ast.eval()",
		},
		{
			col = 9,
			lnum = 40,
			path = "src/runtime.rs",
			severity = vim.diagnostic.severity.ERROR,
			text = "explicit panic",
		},
	}, r)
end)
