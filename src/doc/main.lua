-- Local variables
local lineWidth = 80
local modulePrefix = 'love'
local tabWidth = 8

-- You can replace this with a tab character if you desire. Just be sure to
-- remove the 'rep' portion
local tabStr = (' '):rep( tabWidth )

-- Load api
local api = require 'love-api.love_api'

-- Format a string to be highlighted as a ref
local function formatStringAsRef( str )
	return '|' .. modulePrefix .. '-' .. str .. '|'
end

-- Format a string to be highlighted as a tag
local function formatStringAsTag( str )
	return '*' .. modulePrefix .. '-' .. str .. '*'
end
