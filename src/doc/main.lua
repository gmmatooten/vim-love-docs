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
local tabString = (' '):rep( tabWidth )

-- Width of tags in the table of contents
local tableOfContentsTagWidthLimit = 20

-- Fallback for if a variant has no description
local defaultFunctionVariantDescription = 'See function description.'

-- Give align module these changes
align.setDefaultWidth( lineWidth )
align.setTabWidth( tabWidth )
align.setTabStr( tabString )
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
local function shortenString( str, width )
	return #str < width and str or str:sub( 1, width - 1 ) .. '-'
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

-- Gets the overview of a function, including its tag, name, description, and variants
local function getFunctionOverview( func, parentName )
	-- Include tag, name, reference number, and description
	local returnString = align.right( formatStringAsTag( parentName .. func.name ) ) .. '\n'
	.. referenceNumber .. ' ' .. func.name .. '\n\n'
	.. align.left( func.description ) .. '\n\n'
	.. 'Variants:\n'

	-- Include variants
	for variantIndex, variant in ipairs( func.variants ) do
		-- Give a default description if one is not present
		local variantDescription = variant.description or defaultFunctionVariantDescription

		-- Include its index
		local currentFunc = tabString .. variantIndex .. '.'

		-- Align all descriptions to start at the same point
		currentFunc = currentFunc .. (' '):rep( 2 * tabWidth - #currentFunc )

		-- Include variant descriptions
		local indentString = (' '):rep( #currentFunc )
		currentFunc = currentFunc .. align.left( variantDescription, indentString, nil, true )
		returnString = returnString .. '\n' .. currentFunc .. '\n\n'

		-- Parameters
		local parametersString = '()'
		local parametersExtendedString = 'None'

		if variant.arguments and #variant.arguments > 0 then
			local names = {}

			for _, param in ipairs( variant.arguments ) do
				table.insert( names, param.name )
			end

			parametersString = '( ' .. table.concat( names, ', ' ) .. ' )'
		end

		-- Return values
		local returnValuesString = ''
		local returnValuesExtendedString = tabString:rep( 3 ) .. 'None'

		if variant.returns and #variant.returns > 0 then
			local names = {}

			returnValuesExtendedString = ''

			for _, ret in ipairs( variant.returns ) do
				table.insert( names, ret.name )

				returnValuesExtendedString = returnValuesExtendedString
				.. tabString:rep( 3 ) .. ret.name .. ': <' .. ret.type .. '>' .. '\n\n'
				.. align.left( ret.description, tabString:rep( 4 ) ) .. '\n\n'
			end

			returnValuesString = table.concat( names, ', ' ) .. ' = '
		end

		-- Function name
		local functionNameRef = '|' .. parentName .. func.name .. '|'

		-- Put it all together
		local variantSynopsis = returnValuesString .. functionNameRef .. parametersString
		returnString = returnString .. align.left( variantSynopsis, indentString .. tabString ) .. '\n\n'
		.. tabString:rep( 2 ) .. 'Return Values:\n\n'
		.. returnValuesExtendedString .. '\n'
	end

	return returnString
end

-- Gets the aspects of module[attribute] as a string
-- module is the table containing the module's information
-- attributeName is the name of the aspect you would like to get, e.g. types, enums, etc.
-- tagPrefix is the prefix that precedes all tags
-- parentName is the name of the attribute's parent (i.e. love.audio, etc.)
local function getAttributeInformation( module, attributeName, tagPrefix, parentName )
	tagPrefix = tagPrefix or ''

	-- Right align the tag
	local returnString = align.right( formatStringAsTag( module.name .. '-' .. attributeName ) ) .. '\n'
	-- Include the reference number and name
	.. referenceNumber .. ' ' .. attributeName .. ':\n\n'
	-- And a (very) basic description
	.. 'The ' .. attributeName .. ' of ' .. parentName .. '.' .. '\n\n'

	-- Show the contents of the attributeName (if any)
	if module[attributeName] and #module[attributeName] > 0 then
		for _, attr in ipairs( module[attributeName] ) do
			local line = tabString .. attr.name
			line = line .. align.right( formatStringAsRef( tagPrefix .. attr.name ), ' ', lineWidth - #line )

			returnString = returnString .. line .. '\n'
		end
	else
		returnString = returnString .. tabString .. 'None\n'
	end

	return returnString
end

-- Gets the overview of the module
-- module is the table containing the module's information
local function getModuleOverview( module )
	local returnString = align.right( formatStringAsTag( module.name ) ) .. '\n'
	.. referenceNumber .. ' ' .. module.name .. '\n'
	.. '\n'
	.. align.left( module.description ) .. '\n'

	return returnString
end

for _, module in ipairs( api.modules ) do
	incrementRefNumber()

	local parentName = ('love.%s'):format( module.name )

	print( getModuleOverview( module ) )

	addRefNumberSection()

	incrementRefNumber()
	print( getAttributeInformation( module, 'types', '', parentName ) )

	if module.types then
		addRefNumberSection()

		for _, Type in ipairs( module.types ) do
			incrementRefNumber()
			print( getModuleOverview( Type ) )

			addRefNumberSection()
			incrementRefNumber()
			print( getAttributeInformation( Type, 'functions', Type.name .. ':', Type.name ) )
			removeRefNumberSection()
		end

		-- constructors
		-- parenttype
		-- supertype

		removeRefNumberSection()
	end

	incrementRefNumber()
	print( getAttributeInformation( module, 'enums', '', parentName ) )

	if module.enums then
		addRefNumberSection()

		for _, enum in ipairs( module.enums ) do
			incrementRefNumber()
			print( getModuleOverview( enum ) )

			addRefNumberSection()
			incrementRefNumber()
			print( getAttributeInformation( enum, 'constants', enum.name .. '-', enum.name ) )
			removeRefNumberSection()
		end

		removeRefNumberSection()
	end

	incrementRefNumber()
	print( getAttributeInformation( module, 'functions', parentName .. '.', parentName  ) )

	if module.functions then
		addRefNumberSection()

		for _, func in ipairs( module.functions ) do
			incrementRefNumber()
			print( getFunctionOverview( func, parentName .. '.' ) )
		end

		removeRefNumberSection()
	end

	removeRefNumberSection()
end
