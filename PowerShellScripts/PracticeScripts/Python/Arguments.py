#print('top')
#print('bottom')

'''
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("a", help="Provide a integer value", type=int)
parser.add_argument("b", help="Provide a integer value", type=int)
parser.add_argument("-s","--sum", help="Add the integers", action = "store_true")
parser.add_argument("--n", help="Provide a integer value", type=int, nargs='?', default = 3 ) 
args = parser.parse_args()
print(args)
'''
#print('yes')
'''class Person:
    name = "Akshi"
    gender = "Female"
    def read(self):
        print('Hello! You are in Person class')
        print(self.name)
dir(Person)

a = Person()
a.name
'''
'''
class ManglingTest:
    def __init__(self):
        self.__mangled = 'hello'

    def get_mangled(self):
        return self.__mangled

test=ManglingTest()
test.get_mangled()
dir(test)
'''

from random import *
array = [1,2,3,4]
print(array)
randint(1,10)
print('Random integer:', array)
shuffle(array)
print('shuffled array:', array)

