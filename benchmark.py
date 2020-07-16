import random
counter = random.randint(1, 100)

def add(a):
	global counter
	counter += a
	return counter

def sub(b):
	global counter
	counter -= b
	return counter
