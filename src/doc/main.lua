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

-- TODO: Handle containing tabs in text
-- (width calculation currently relies on the length of string, so spaces are required)
local tabStr = (' '):rep( tabWidth )

-- Width of tags in the table of contents
local tableOfContentsTagWidthLimit = 20

-- Width of listings in the TOC
-- (-3 is to give space between listing and reference)
local tableOfContentsListingWidthLimit = lineWidth - tableOfContentsTagWidthLimit - #formatStringAsTag( '' ) - 3

-- Give align these changes
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
-- Shorten a string if it is longer than width
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
	local rightAlignedTag = align.right( tableOfContentsTag, '.', lineWidth - #tableOfContentsListing )

	tableOfContentsListing = tableOfContentsListing .. rightAlignedTag
	print( tableOfContentsListing )
end
-- }}}

-- Create a lookup table for tags
local tags = {}

-- Loop over modules
-- prefix is the name that prefaces tags
-- funcSeparator specifies how to separate functions ('.', ':', etc.)
local function extractData( module, prefix, funcSeparator )
	prefix = prefix or 'love.'
	funcSeparator = funcSeparator or '.'

	incrementRefNumber()
	addSection( referenceNumber, module.name, prefix .. module.name )

	-- Extract data from module {{{
	-- Add type information
	addRefNumberSection()

	if module.types and #module.types > 0 then
		incrementRefNumber()

		addSection( referenceNumber, 'types', module.name .. '-types' )
		addRefNumberSection()

		for _, moduleType in ipairs( module.types ) do
			extractData( moduleType, '', ':' )
		end

		removeRefNumberSection()
	end

	-- Add enum information
	if module.enums and #module.enums > 0 then
		incrementRefNumber()

		addSection( referenceNumber, 'enums', module.name .. '-enums' )
		addRefNumberSection()

		for _, moduleEnum in ipairs( module.enums ) do
			extractData( moduleEnum, '', ':' )
		end

		removeRefNumberSection()
	end

	-- Add constants information
	if module.constants and #module.constants > 0 then
		incrementRefNumber()

		addSection( referenceNumber, 'constants', module.name .. '-constants' )
		addRefNumberSection()

		for _, moduleConstants in ipairs( module.constants ) do
			extractData( moduleConstants, module.name .. '-', '-' )
		end

		removeRefNumberSection()
	end

	-- Add function information
	if module.functions and #module.functions > 0 then
		incrementRefNumber()

		addSection( referenceNumber, 'functions', module.name .. '-functions' )
		addRefNumberSection()

		for _, moduleFunction in ipairs( module.functions ) do
			extractData( moduleFunction, prefix .. module.name .. funcSeparator, funcSeparator )
		end

		removeRefNumberSection()
	end

	removeRefNumberSection()
	-- }}}
end

for _, module in ipairs( api.modules ) do
	extractData( module )
end
