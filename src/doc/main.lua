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

-- Give align module these changes
align.setDefaultWidth( lineWidth )
align.setTabWidth( tabWidth )
align.setTabStr( tabStr )
-- }}}

-- Header {{{
local header = [[
*love.txt* *love2d*                  Documentation for the LOVE game framework.

                         _       o__o __      __ ______ ~
                        | |     / __ \\ \    / //  ____\~
                        | |    | |  | |\ \  / / | |__   ~
                        | |    | |  | | \ \/ /  |  __|  ~
                        | |____| |__| |  \  /   | |____ ~
                        \______|\____/    \/    \______/~

                    The complete solution for Vim with LOVE.
                    Includes highlighting and documentation.
]]
-- }}}

-- Misc. utility functions {{{
-- Shorten str if it is longer than width
local function abbreviateString( str, width )
	return #str < width and str or str:sub( 1, width - 1 ) .. '-'
end

local function basicDescription( aspect, funcName )
	return 'The ' .. aspect .. ' for ' .. funcName
end
-- }}}

-- Reference number {{{
-- Modularized {{{
-- Increase the last digit of ref by one
local function incrementReferenceNumber( ref )
	local base, tail = ref:match( '^(.-)(%d+)%.$' )
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

-- Sections {{{
-- Keep track of all the tags used to find any matching text
local tags = {}

-- Stores the contents of the table of contents
local tableOfContents = ''

-- Stores the contents of as a table (can't use a string; not enough memory)
local contents = {}

-- referenceNumber and name are used for the listing
-- tag is the string used as the ref/tag (NOT '|love-tag|', just 'tag')
local function addSection( referenceNumber, module, tagName, tag, aspectName, funcName )
	tag = tag or tagName

	-- Use a hash to make looking up words easier, plus prevents duplicates
	tags[tag] = true

	if type( module ) == 'table' then
		module.description = module.description or basicDescription( aspectName, funcName )
	end

	-- Table of contents {{{
	-- Determine indentation level
	local _, numberOfIndents = referenceNumber:gsub( '%.', '' )
	numberOfIndents = numberOfIndents - 1
	local indentation = tabStr:rep( numberOfIndents )

	-- Format tag to the specified length
	local tableOfContentsTag = abbreviateString( tag, tableOfContentsTagWidthLimit )

	-- Space before is for padding
	tableOfContentsTag = ' ' .. formatStringAsRef( tableOfContentsTag )

	-- Shorten listing if it's too long
	local listingNumberAndName = referenceNumber .. ' ' .. tagName
	local tableOfContentsListing = indentation .. listingNumberAndName
	-- (-2 is for space and period for separation)
	local widthLimit = lineWidth - #tableOfContentsTag - 2
	tableOfContentsListing = abbreviateString( tableOfContentsListing, widthLimit )

	-- Space after is for padding
	tableOfContentsListing = tableOfContentsListing .. ' '

	-- Right-align tag
	-- (width includes #tableOfContentsListing to account for text already on the line)
	local rightAlignedTag = align.right( tableOfContentsTag, '.', lineWidth - #tableOfContentsListing )

	tableOfContentsListing = tableOfContentsListing .. rightAlignedTag
	tableOfContents = tableOfContents .. '\n' .. tableOfContentsListing
	-- }}}

	-- Contents {{{
	local currentContent = ''
	if numberOfIndents == 0 then
		currentContent = currentContent .. ('='):rep( lineWidth )
	else
		currentContent = currentContent .. ('-'):rep( lineWidth )
	end

	currentContent = currentContent .. '\n' .. align.right( abbreviateString(
		formatStringAsTag( tag ), lineWidth ), ' '
	) .. '\n' .. listingNumberAndName .. '\n\n'

	-- Description
	.. align.left( module.description or '', 0 ) .. '\n'
	-- Types
	.. ( module.types and #module.types > 0 and '\nTypes:\n' or '' )
	-- Supertypes
	-- Subtypes
	-- ParentType
	-- Constructors
	-- Enums
	-- Constants
	-- Callbacks
	-- Functions

	-- Variants
	-- Notes

	-- Add currentContents to content
	table.insert( contents, currentContent )
	-- }}}
end
-- }}}

-- Extract data and subdata {{{
-- Declare extractData earlier, so that extractSubData can reference it
local extractData

-- Extract specific sub-elements of a module (sectionName), such as types/enums
-- module, prefix, and funcSeparator all have the same meaning as with extractData
local function extractSubData( module, sectionName, prefix, funcSeparator, funcName )
	local section = module[sectionName]

	if section and #section > 0 then
		-- Update reference number and add new subsection
		incrementRefNumber()
		addSection( referenceNumber, section, sectionName, module.name .. '-' .. sectionName, sectionName, funcName )
		addRefNumberSection()

		-- Loop over information in section
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

	local funcName = prefix .. module.name

	-- Increment reference and add section about the current module
	incrementRefNumber()
	addSection( referenceNumber, module, module.name, module.name, funcName )

	-- Extract data from module {{{
	-- Make a new section for sub-information (types, etc.)
	addRefNumberSection()

	-- Types
	extractSubData( module, 'types', '', ':', funcName )

	-- Supertypes
	if module.supertypes and #module.supertypes > 0 then
		incrementRefNumber()
		addSection( referenceNumber, module.supertypes, module.name .. '-supertypes', module.name .. '-supertypes', 'supertypes', funcName )
	end

	-- Subtypes
	if module.subtypes and #module.subtypes > 0 then
		incrementRefNumber()
		addSection( referenceNumber, module.subtypes, module.name .. '-subtypes', module.name .. '-subtypes', 'subtypes', funcName )
	end

	-- ParentType
	if module.parenttype then
		incrementRefNumber()
		addSection( referenceNumber, module.parenttype, module.name .. '-parenttype', module.name .. '-parenttype', 'parenttype', funcName )
	end

	-- Constructors
	if module.constructors and #module.constructors > 0 then
		incrementRefNumber()
		addSection( referenceNumber, module.constructors, module.name .. '-constructors', module.name .. '-constructors', 'constructors', funcName )
	end

	-- Enums
	extractSubData( module, 'enums', '', ':', funcName )

	-- Constants
	extractSubData( module, 'constants', module.name .. '-', '-', funcName )

	-- Callbacks
	extractSubData( module, 'callbacks', funcName .. funcSeparator, funcSeparator, funcName )

	-- Functions
	extractSubData( module, 'functions', funcName .. funcSeparator, funcSeparator, funcName )

	removeRefNumberSection()
	-- }}}
end
-- }}}

-- Output the documentation {{{
for _, module in ipairs( api.modules ) do
	extractData( module )
end

print( header )
print( tableOfContents .. '\n' )
print( table.concat( contents, '\n' ) )
-- }}}
