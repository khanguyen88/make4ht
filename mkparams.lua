local lapp = require "lapp-mk4"
local mkutils = require "mkutils"
local m = {} -- use ugly module system for new lua versions support

m.optiontext =  [[
${progname} - build system for tex4ht
Usage:
${progname} [options] filename ["tex4ht.sty op." "tex4ht op." "t4ht op" "latex op"]
-c,--config (default xhtml) Custom config file
-d,--output-dir (default nil)  Output directory
-l,--lua  Use lualatex for document compilation
-m,--mode (default default) Switch which can be used in the makefile 
-n,--no-tex4ht Disable dvi file processing with tex4ht command
-s,--shell-escape Enables running external programs from LaTeX
-u,--utf8  For output documents in utf8 encoding
-x,--xetex Use xelatex for document compilation
]]
local function get_args(parameters, optiontext)
	local parameters = parameters or {}
	parameters.progname = parameters.progname or "make4ht"
	parameters.postparams = parameters.postparams or ""
	local optiontext = optiontext or m.optiontext
	parameters.postfile = parameters.postfile or ""
	optiontext = optiontext .. parameters.postparams .."<filename> (string) Input file name\n" .. parameters.postfile 
	--print("--------------\n" .. optiontext .."--------------\n")
	return lapp(optiontext % parameters)
end
m.get_args = get_args
return m
