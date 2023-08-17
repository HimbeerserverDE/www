#!/usr/bin/env lua

local cgi = require "cgi"
local file = require "file"

cgi.serve(file.process("/guide/vf6.md", nil, "--toc"))
