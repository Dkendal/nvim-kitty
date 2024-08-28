local here = require("test_support").here
local nodejs_parser = require("nvim-kitty.parsers.nodejs")

describe("nodejs_parser", function()
    it("should parse error message with stack trace", function()
        local input =
            here(
                [[
                Trace: oops
                    at Object.<anonymous> (/app/scratch.js:4:9)
                    at Module._compile (node:internal/modules/cjs/loader:1358:14)
                    at Module._extensions..js (node:internal/modules/cjs/loader:1416:10)
                    at Module.load (node:internal/modules/cjs/loader:1208:32)
                    at Module._load (node:internal/modules/cjs/loader:1024:12)
                    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:174:12)
                    at node:internal/main/run_main_module:28:49
                ]]
            )

        local result = nodejs_parser:match(input)

        assert.are.same({
            {
                text = 'oops',
                module = "Object.<anonymous>",
                path = "/app/scratch.js",
                lnum = 4,
                type = vim.diagnostic.severity.INFO,
            },
            {
                text = 'oops',
                module = "Module._compile",
                path = "node:internal/modules/cjs/loader",
                lnum = 1358,
                type = vim.diagnostic.severity.INFO,
            },
            {
                text = 'oops',
                module = "Module._extensions..js",
                path = "node:internal/modules/cjs/loader",
                lnum = 1416,
                type = vim.diagnostic.severity.INFO,
            },
            {
                text = 'oops',
                module = "Module.load",
                path = "node:internal/modules/cjs/loader",
                lnum = 1208,
                type = vim.diagnostic.severity.INFO,
            },
            {
                text = 'oops',
                module = "Module._load",
                path = "node:internal/modules/cjs/loader",
                lnum = 1024,
                type = vim.diagnostic.severity.INFO,
            },
            {
                text = 'oops',
                module = "Function.executeUserEntryPoint [as runMain]",
                path = "node:internal/modules/run_main",
                lnum = 174,
                type = vim.diagnostic.severity.INFO,
            },
            {
                text = 'oops',
                module = "node:internal/main/run_main_module",
                path = "node:internal/main/run_main_module",
                lnum = 28,
                type = vim.diagnostic.severity.INFO,
            },

        }, result)
    end)
end)
