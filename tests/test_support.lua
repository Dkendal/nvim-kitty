local test_support = {}

--- Act like a here document with indentation. The indentation of the first line
--- is the baseline, and all other lines are indented to match. Output string
--- should be trimmed of this baseline indentation.
function test_support.here(doc)
	local baseline = string.match(doc, "[^\n]%s*%S")
	baseline = string.gsub(baseline, "%S", "")
	--
	return doc:gsub("^" .. baseline, ""):gsub("\n" .. baseline, "\n"):gsub("%s+\n", "\n"):gsub("%s+$", "\n")
end

return test_support
