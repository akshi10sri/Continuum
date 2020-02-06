#STRING OPERATIONS
	* Concatenation - addition operator(+)
	'Akshi' + ' Srivastava' = 'Akshi Srivastava'
                      OR
	a='Akshi'
	a + ' Srivastava'
	'Akshi Srivastava'

	* Repetition - Multiplication operator(*)
	'Akshi'*2
	'AkshiAkshi'
		OR
	a*2
	'AkshiAkshi'

#FORMAT METHOD( '.format()' )
	* "Hello {} in {} world".format('Akshi','Python')
	Hello Akshi in Python world
	* "Hello {0} in {1} world".format('Akshi','Python')
	Hello Akshi in Python world
***Its not mandate to specify index on left side of method. It automatically assumes the values in sequence they are defined in format() as a argument
	* '{0:04d}'.format(5)     #addign leading zero
	0005

#SUBSTRING/STRING SLICE
	• Range Operator(:) - It will substring/slice a string in python from one defined index to other defined index 
	String="Hello! Welcome to Python world"
	String[1:14] = ello! Welcome  #slicing string from an index 1 to index 13
	String[18:] = Python world #no end index is defined then it is treated as up to last index
	String[18:None] = Python world #None specify the last index
	String[:4] = Hell #no beginning index is defined then it is treated as zero index
	 *Include character at starting index but exclude character at specified last index.
	
	• Slice notation has 3 important arguments: start, stop and step
	Val='acbdcedfegfig'
	Val[0:None:2] = abcdefg # It will print from character at 0 to last index but every time increment index by 2
	Val[5:None:None] = edfegfig # It will print string from index 5 to last'
	Val[5:None:-1] = ecdbca #It will print from character at index 5 to 0 index
	Val[5:None:-2] = edc #It will print from character at index 5 to 0 index but decrement index value by 2

TESTING STRING MEMBERSHIP
	• We can test existence of a character/substring within a string by using 'in' and 'not in' keyword
	'a' in 'abcd' = True  #Testing a character 'a' in string 'abcd'
	'ab' in 'abcd' = True #Testing a substring 'ab' in string 'abcd'
	'g' not in 'abcd' = True
	'gfh' not in 'abcd' = True
	
INBUILT METHODS FOR MANIPULATIONS
	• Length of string
	len('s') = 1
	len('abcd') = 4
	• Find starting index of character or a substring
	'scripting'.index('t') = 5
	'scripting'.index('rip') = 2
	• Case Change
	print('python world'.capitalize()) = Python world #Capitalize first character of string
	print('python world'.upper()) = PYTHON WORLD #Capitalize all words or characters
	print('python world'.title()) = Python World #Capitalize first alphabet of each word
	• Split and Join Strings
	print('ab cd ef'.split(' ')) = ['ab', 'cd', 'ef']  # split string by white space
	print(' '.join('Python')) = P y t h o n # join each char in string with space
	• Reverse String
	print(''.join(reversed('python'))) = nohtyp #reversign a string
	print(''.join(list('python')[::-1])) = nohtyp # reversing a string
	• Remove Whitespace
	print('  Hey Hello  '.strip()) = 'Hey Hello'  #remove white spaces from both ends 
	print('  Hey Hello  '.lstrip()) = 'Hey Hello  '  #remove white spaces from left ends
	print('  Hey Hello  '.rstrip()) = '  Hey Hello'  #remove white spaces from right end 
	• Text Alignment
	print('Hello'.rjust(10,'-')) =----------Hello # string adjustment to right
	print('Hello'.ljust(10,'-')) = Hello---------- #strign adjustment to left
	print('Hello'.center(5,'-')) = -----Hello----- #string adjustment to center
