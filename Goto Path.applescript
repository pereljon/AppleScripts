-- Goto Path.workflow
-- version 1.0
-- by Jonathan Perel
-- 3/6/2015
-- This AppleScript is executed in a "Run AppleScript" Automator workflow script step.
-- Create the Automator workflow as a service which received text from any application.

on run {input, parameters}
	-- Save previous delimiter
	set savedDelimiters to AppleScript's text item delimiters
	repeat with thePOSIXPath in input
		if {thePOSIXPath starts with "file:///"} then
			-- Clean up "file:///" URL input
			set thePOSIXPath to replace_chars(thePOSIXPath, "file://", "")
			set thePOSIXPath to replace_chars(thePOSIXPath, "%20", " ")
			set thePOSIXPath to replace_chars(thePOSIXPath, "%22", "\"")
			-- Set delimiter to POSIX path separator "/" 
			set AppleScript's text item delimiters to {"/"}
			set thePOSIXPath1 to text item 2 of (thePOSIXPath as string)
			if thePOSIXPath1 is equal to "Volumes" then
				-- Path is non-volume
				set thePOSIXPath2 to text item 3 of (thePOSIXPath as string)
				-- Check to see if the volume is mounted
				repeat
					tell application "Finder" to set volumeExists to disk thePOSIXPath2 exists
					if not volumeExists then
						-- Volume is not mounted. Ask to mount.			
						set theReturnedItems to (display dialog "\"" & thePOSIXPath2 & "\" volume is not mounted.
Please mount it and press Continue to open the URL." buttons {"Cancel", "Continue"} default button 2)
						set theButtonName to the button returned of theReturnedItems
						if theButtonName is equal to "Cancel" then
							exit repeat
						end if
					else
						exit repeat
					end if
				end repeat
				-- Convert POSIX path to Mac OS path
				set theMacPath to ((POSIX file thePOSIXPath) as text)
				-- Set delimiter to Mac OS path separator ":"
				set AppleScript's text item delimiters to {":"}
				-- Get Mac OS path as list
				set theMacPathList to every text item of (theMacPath as string)
				if (theMacPath does not end with ":") then
					-- Ask whether to open file or enclosing folder
					set theReturnedItems to (display dialog theMacPath & "
Open this file or open its enclosing folder?" buttons {"Open File", "Open Folder"} default button 2)
					set theButtonName to the button returned of theReturnedItems
					if theButtonName is equal to "Open Folder" then
						-- Get enclosing folder path
						set theMacPathList to items 1 thru -2 of theMacPathList
						set theMacPath to ((theMacPathList as text) as alias)
						-- Set to bring Finder to front (openning folder path)
						set bringFinderToFront to true
					end if
				else
					-- Set to bring Finder to front (openning folder path)
					set bringFinderToFront to true
				end if
				try
					-- Open path in Finder
					tell application "Finder" to open theMacPath
					if bringFinderToFront is true then tell application "System Events" to set frontmost of process "Finder" to true
				on error errMsg number errorNumber
					display dialog (errorNumber as string) & " : " & errMsg
				end try
			else
				set theReturnedItems to (display dialog thePOSIXPath & "
This is not a valid link." buttons {"Cancel", "Continue"} default button 2)
				set theButtonName to the button returned of theReturnedItems
				if theButtonName is equal to "Cancel" then
					exit repeat
				end if
			end if
		else
			-- do we want to do something here for boot volume URLs?
		end if
	end repeat
	-- Restore saved delimiter
	set AppleScript's text item delimiters to savedDelimiters
end run

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars
