-- Align monospaced text

-- Variables that control the output
local defaultWidth = 79
local tabWidth = 8
local tabStr = (' '):rep( tabWidth )

-- Change the global defaultWidth
local function setDefaultWidth( n )
	defaultWidth = n
end

-- Add a new line
local function newLine( currentLine, textWidth, determineSpacing )
	if not currentLine:match( '^(%s*)$' ) then
		-- Ignore blank lines/lines that consist solely of whitespace
		return (' '):rep( determineSpacing( currentLine, textWidth ) ) .. currentLine .. '\n'
	else
		return ''
	end
end

-- Determine the number of spaces required to align currentLine
local function determineRightAlignSpacing( currentLine, textWidth )
	return textWidth - #currentLine
end

-- Right-align text to a given width
local function alignRight( text, textWidth )
	textWidth = textWidth or defaultWidth

	-- currentLine is the line that will be added next
	-- output is the entire wrapped message
	local currentLine, output = '', ''

	-- Replace tabs to account for their width appropriately
	text = text:gsub( '\t', tabStr )

	-- Respect newlines. To do this, loop over by lines.
	-- Add a new line to text to handle all cases (removed later)
	text = text .. '\n'
	text:gsub( '(.-)\n', function( line )
		-- Reset the current line
		currentLine = ''

		-- Loop over words (separated by spaces)
		-- Add space to beginning of line to make linebreaks easier to determine
		line = ' ' .. line
		line:gsub( '(%s+)(%S+)', function( spacing, word )
			-- Remove any spaces at the start of currentLine
			currentLine = currentLine:match( '^%s*(.*)$' )

			if #currentLine + #spacing + #word <= textWidth then
				-- Word is short enough
				currentLine = currentLine .. spacing .. word
			else
				if #currentLine == 0 then
					-- If currentLine is blank and it's too long, hyphenate it
					while #word > textWidth do
						-- Trim word
						currentLine = word:sub( 1, textWidth - 1 ) .. '-'
						output = output .. newLine( currentLine, textWidth, determineRightAlignSpacing )
						word = word:sub( textWidth )
					end
				else
					-- word is short enough to not be hyphenated
					output = output .. newLine( currentLine, textWidth, determineRightAlignSpacing )
				end

				-- Update the current line
				currentLine = word
			end
		end )

		output = output .. newLine( currentLine, textWidth, determineRightAlignSpacing )
		currentLine = ''
	end )

	-- Remove new line added earlier
	return output:match( '^(.-)\n$' )
end

return {
	alignRight = alignRight,
}
