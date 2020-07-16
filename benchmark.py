counter = 0

def add(a):
	global counter
	counter += a
	return counter

def sub(b):
	global counter
	counter -= b
	return counter

def reset():
	global counter
	counter = 0