local lpeg = require("lpeglabel")
local l = {}
local vim = _G.vim
lpeg.locale(l)
local _local_1_ = lpeg
local string = _local_1_["P"]
local capture = _local_1_["C"]
local group = _local_1_["Cg"]
local to_table = _local_1_["Ct"]
local helper = require("nvim-kitty.parsers.helper")
local h = require("nvim-kitty.parsers.helper")
local _local_2_ = helper
local path = _local_2_["path"]
local colon = _local_2_["colon"]
local char = _local_2_["char"]
local linefeed = _local_2_["linefeed"]
local rest_of_line = _local_2_["rest_of_line"]
local error_type = _local_2_["error_type"]
local set_tag = _local_2_["set_tag"]
local text = _local_2_["text"]
local repeat1 = _local_2_["repeat1"]
local while_not1 = _local_2_["while_not1"]
local optional = _local_2_["optional"]
local flatten = _local_2_["flatten"]
local mix_error_detail = (function(tgt, m, ...)
	return tgt[m](tgt, ...)
end)(
	(function(tgt, m, ...)
		return tgt[m](tgt, ...)
	end)(
		(function(tgt, m, ...)
			return tgt[m](tgt, ...)
		end)(
			(function(tgt, m, ...)
				return tgt[m](tgt, ...)
			end)(
				(function(tgt, m, ...)
					return tgt[m](tgt, ...)
				end)(string("  "), "*", path),
				"*",
				colon
			),
			"*",
			group((capture((l.digit ^ 1)) / tonumber), "lnum")
		),
		"*",
		colon
	),
	"*",
	group((capture((char ^ 0)) / vim.trim), "module")
)
local mix_error = to_table(
	(function(tgt, m, ...)
		return tgt[m](tgt, ...)
	end)(
		(function(tgt, m, ...)
			return tgt[m](tgt, ...)
		end)(
			(function(tgt, m, ...)
				return tgt[m](tgt, ...)
			end)(
				(function(tgt, m, ...)
					return tgt[m](tgt, ...)
				end)(group((string("error") / error_type), "severity"), "*", colon),
				"*",
				group((rest_of_line / vim.trim), "text")
			),
			"*",
			mix_error_detail
		),
		"*",
		linefeed
	)
)
local mix_warning = to_table(
	(function(tgt, m, ...)
		return tgt[m](tgt, ...)
	end)(
		(function(tgt, m, ...)
			return tgt[m](tgt, ...)
		end)(
			(function(tgt, m, ...)
				return tgt[m](tgt, ...)
			end)(
				(function(tgt, m, ...)
					return tgt[m](tgt, ...)
				end)(group((string("warning") / error_type), "severity"), "*", colon),
				"*",
				group((rest_of_line / vim.trim), "text")
			),
			"*",
			mix_error_detail
		),
		"*",
		linefeed
	)
)
local mix_compile_error = to_table((function(tgt, m, ...)
	return tgt[m](tgt, ...)
end)(
	(function(tgt, m, ...)
		return tgt[m](tgt, ...)
	end)(
		(function(tgt, m, ...)
			return tgt[m](tgt, ...)
		end)(string("** (CompileError) "), "*", path),
		"*",
		colon
	),
	"*",
	group((capture((char ^ 0)) / vim.trim), "text")
))
local function mod_umbrella_app(tbl)
	local app = (tbl.module):match("((%S+)%s+%S+)")
	if app == "elixir" then
	else
		if app then
			tbl.path = ("apps/" .. app .. "/" .. tbl.path)
		else
		end
	end
	return tbl
end
return mod_umbrella_app
