local t = require("test_support")
local parser = require("nvim-kitty.parsers").wrap(require("nvim-kitty.parsers.nodejs"))

pending("processes nodejs stacktraces", function()
	local corpus = t.here([[
		⠋ Waiting for login page...⠋ Seeding local database...Error: Protocol error (Target.detachFromTarget): No session with given id
				at /Users/dylan.kendal/src/boulevard/blvd-migrations/node_modules/puppeteer/lib/cjs/puppeteer/common/Connection.js:71:63
				at new Promise (<anonymous>)
				at Connection.send (/Users/dylan.kendal/src/boulevard/blvd-migrations/node_modules/puppeteer/lib/cjs/puppeteer/common/Connection.js:70:16)
				at CDPSession.detach (/Users/dylan.kendal/src/boulevard/blvd-migrations/node_modules/puppeteer/lib/cjs/puppeteer/common/Connection.js:244:32)
				at PuppeteerHar.stop (/Users/dylan.kendal/src/boulevard/blvd-migrations/node_modules/puppeteer-har/lib/PuppeteerHar.js:108:27)
				at process.processTicksAndRejections (node:internal/process/task_queues:95:5) {
			level: 'error',
			timestamp: '2024-08-14T14:13:34.850Z',
			[Symbol(level)]: 'error',
			[Symbol(message)]: '[ERROR] [2024-08-14T14:13:34.850Z]: Protocol error (Target.detachFromTarget): No session with given id '
		}
		✖ An unhandled error occurred, terminating process
	]])

	local r, l, e = parser:match(corpus)

	assert.equal(nil, l)
	assert.equal(nil, e)
	assert.same({
		{},
	}, r)
end)
