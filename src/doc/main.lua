-- Output the contents of LOVE documentation for vim

-- Prefix of all tags
local modulePrefix = 'love'

-- Requires {{{
-- Load api
local api = require 'love-api.love_api'

-- Align text
local align = require( 'align' )
-- }}}

-- Ref and tag formatting {{{
-- Format a string to be highlighted as a ref
local function formatStringAsRef( str )
	return '|' .. modulePrefix .. '-' .. str .. '|'
end

-- Format a string to be highlighted as a tag
local function formatStringAsTag( str )
	return '*' .. modulePrefix .. '-' .. str .. '*'
end
-- }}}

-- Local variables {{{
-- Width that lines should be wrapped to
local lineWidth = 79

-- Width of tabs
-- (8 spaces is too much, some content gets cut off)
local tabWidth = 4

-- TODO: Handle using actual tabs (\t) in text
-- (width calculation currently relies on the length of string, so spaces are required)
local tabStr = (' '):rep( tabWidth )

-- Width of tags in the table of contents
local tableOfContentsTagWidthLimit = 20

-- Width of listings in the TOC
-- (-3 is to give space between listing and reference)
local tableOfContentsListingWidthLimit = lineWidth - tableOfContentsTagWidthLimit - #formatStringAsTag( '' ) - 3

-- Give align module these changes
align.setDefaultWidth( lineWidth )
align.setTabWidth( tabWidth )
align.setTabStr( tabStr )
-- }}}

-- Reference number {{{
-- Modularized {{{
-- Increase the last digit of ref by one
local function incrementReferenceNumber( ref )
	base, tail = ref:match( '^(.-)(%d+)%.$' )
	return base .. ( tonumber( tail ) + 1 ) .. '.'
end

-- Add a new section to the reference number
local function addReferenceNumberSection( ref )
	return ref .. '0.'
end

-- End a reference number section
local function removeReferenceNumberSection( ref )
	return ref:match( '^(.-)%d+%.$' )
end
-- }}}

-- Using referenceNumber {{{
local referenceNumber = '0.'

local function incrementRefNumber()
	referenceNumber = incrementReferenceNumber( referenceNumber )
end

local function addRefNumberSection()
	referenceNumber = addReferenceNumberSection( referenceNumber )
end

local function removeRefNumberSection()
	referenceNumber = removeReferenceNumberSection( referenceNumber )
end
-- }}}
-- }}}

-- Misc. utility functions {{{
-- Shorten str if it is longer than width
local function abbreviateString( str, width )
	return #str < width and str or str:sub( 1, width - 1 ) .. '-'
end
-- }}}

-- Sections {{{
local tableOfContents = {}
local contents = {}

-- referenceNumber and name are used for the listing
-- tag is the string used as the tag (NOT '|love-tag|', just 'tag')
local function addSection( referenceNumber, name, tag )
	tag = tag or name

	-- Determine indentation level
	local _, numberOfIndents = referenceNumber:gsub( '%.', '' )
	numberOfIndents = numberOfIndents - 1
	local indentation = tabStr:rep( numberOfIndents )

	-- Format tag to the specified length
	tableOfContentsTag = abbreviateString( tag, tableOfContentsTagWidthLimit )

	-- Space before is for padding
	tableOfContentsTag = ' ' .. formatStringAsRef( tableOfContentsTag )

	-- Shorten listing if it's too long
	local tableOfContentsListing = indentation .. referenceNumber .. ' ' .. name
	-- (-2 is for space and period for separation)
	local widthLimit = lineWidth - #tableOfContentsTag - 2
	tableOfContentsListing = abbreviateString( tableOfContentsListing, widthLimit )

	-- Space after is for padding
	tableOfContentsListing = tableOfContentsListing .. ' '

	-- Right-align tag
	-- (width includes #tableOfContentsListing to account for text already on the line)
	local rightAlignedTag = align.right( tableOfContentsTag, '.', lineWidth - #tableOfContentsListing )

	tableOfContentsListing = tableOfContentsListing .. rightAlignedTag
	print( tableOfContentsListing )
end
-- }}}

-- Declare extractData earlier, so that extractSubData can reference it
local extractData

local function extractSubData( module, sectionName, prefix, funcSeparator )
	local section = module[sectionName]
	if section and #section > 0 then
		incrementRefNumber()

		addSection( referenceNumber, sectionName, module.name .. '-' .. sectionName )
		addRefNumberSection()

		for _, moduleSubData in ipairs( section ) do
			extractData( moduleSubData, prefix, funcSeparator )
		end

		removeRefNumberSection()
	end
end

-- Loop over modules
-- module is the table containing the api data
-- prefix is the name that prefaces tags (not including modulePrefix)
-- funcSeparator specifies how to separate functions ('.', ':', etc.)
function extractData( module, prefix, funcSeparator )
	-- Give parameters defaults
	prefix = prefix or 'love.'
	funcSeparator = funcSeparator or '.'

	-- Increment reference and add section about the current module
	incrementRefNumber()
	addSection( referenceNumber, module.name, prefix .. module.name )

	-- Extract data from module {{{
	-- Make a new section for sub-information (types, etc.)
	addRefNumberSection()

	-- Add type information
	extractSubData( module, 'types', '', ':' )

	-- Add enum information
	extractSubData( module, 'enums', '', ':' )

	-- Add constants information
	extractSubData( module, 'constants', module.name .. '-', '-' )

	-- Add function information
	extractSubData( module, 'functions', prefix .. module.name .. funcSeparator, funcSeparator )

	removeRefNumberSection()
	-- }}}
end

for _, module in ipairs( api.modules ) do
	extractData( module )
end
