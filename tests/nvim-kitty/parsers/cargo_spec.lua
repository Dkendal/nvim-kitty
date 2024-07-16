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
			 2: core::panicking::panic_display
								 at /rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/panicking.rs:264:5
			 3: newtype::parser::parser_tests::match_ts::{{closure}}::panic_cold_display
								 at /rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/panic.rs:99:13
			 4: newtype::parser::parser_tests::match_ts::{{closure}}
								 at ./src/test_support.rs:19:46
			 5: core::result::Result<T,E>::unwrap_or_else
								 at /rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/result.rs:1456:23
			 6: newtype::parser::parser_tests::match_ts
								 at ./src/test_support.rs:19:20
			 7: newtype::parser::parser_tests::match_ts::{{closure}}
								 at ./src/parser.rs:2117:18
			 8: core::ops::function::FnOnce::call_once
								 at /rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/ops/function.rs:250:5
			 9: core::ops::function::FnOnce::call_once
								 at /rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/ops/function.rs:250:5
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
		{
			col = 5,
			lnum = 264,
			path = "/rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/panicking.rs",
			severity = 1,
			stack_number = "2",
			text = "2: core::panicking::panic_display\n",
		},
		{
			col = 13,
			lnum = 99,
			path = "/rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/panic.rs",
			severity = 1,
			stack_number = "3",
			text = "3: newtype::parser::parser_tests::match_ts::{{closure}}::panic_cold_display\n",
		},
		{
			col = 46,
			lnum = 19,
			path = "./src/test_support.rs",
			severity = 1,
			stack_number = "4",
			text = "4: newtype::parser::parser_tests::match_ts::{{closure}}\n",
		},
		{
			col = 23,
			lnum = 1456,
			path = "/rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/result.rs",
			severity = 1,
			stack_number = "5",
			text = "5: core::result::Result<T,E>::unwrap_or_else\n",
		},
		{
			col = 20,
			lnum = 19,
			path = "./src/test_support.rs",
			severity = 1,
			stack_number = "6",
			text = "6: newtype::parser::parser_tests::match_ts\n",
		},
		{
			col = 18,
			lnum = 2117,
			path = "./src/parser.rs",
			severity = 1,
			stack_number = "7",
			text = "7: newtype::parser::parser_tests::match_ts::{{closure}}\n",
		},
		{
			col = 5,
			lnum = 250,
			path = "/rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/ops/function.rs",
			severity = 1,
			stack_number = "8",
			text = "8: core::ops::function::FnOnce::call_once\n",
		},
		{
			col = 5,
			lnum = 250,
			path = "/rustc/8337ba9189de188e2ed417018af2bf17a57d51ac/library/core/src/ops/function.rs",
			severity = 1,
			stack_number = "9",
			text = "9: core::ops::function::FnOnce::call_once\n",
		},
	}, r)
end)
