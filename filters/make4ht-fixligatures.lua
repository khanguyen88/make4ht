-- fix ligatures
-- replace ligatures produced by tex4ht with their components
-- this prevents problems with some readers
local gsub = unicode.utf8.gsub
function filter(s)
	local replaces = {
		["ﬁ"] = "fi",
		["ﬃ"] = "ffi",
		["ﬂ"] = "fl",
		["ﬄ"] = "ffl"
	}
	return gsub(s, "([ﬁﬃﬂﬄ])",function (x) return replaces[x] or x end)
end

return filter
