"""
import imp
import random
import os
MODULE_EXTENSIONS = ('.py', '.pyc', '.pyo')

def package_contents(package_name):
    file, pathname, description = imp.find_module(package_name)
    if file:
        raise ImportError('Not a package: %r', package_name)
    # Use a set because some may be both source and compiled.
    return set([os.path.splitext(module)[0]
        for module in os.listdir(pathname)
        if module.endswith(MODULE_EXTENSIONS)])

package_contents('random')
"""
"""
import pkgutil
for p in pkgutil.iter_modules():
    print(p[1])

import random
for r in random.iter_modules():
    print(r[1])
"""
'''
import pkgutil
import sys
def explore_package(module_name):    
    loader = pkgutil.get_loader(module_name)
    for sub_module in pkgutil.walk_packages([loader.filename]):
        _, sub_module_name, _ = sub_module
        qname = module_name + "." + sub_module_name
        print(qname)
        explore_package(qname)
#explore_package(sys.argv[1])
explore_package('pkgutil')
'''
name="Python"
print(f'''This is an example of {name}
multiline string enclosed in triple single quotes
at both end of string.''')
#print(string)
name='Akshi'
print(f'single quotes {name}')
f"double quotes {name}"

print(f'''triple single quotes {name}''')
print(f'single quotes {name}')

employee = {'name':{'Language': 'Python', 'Version':3.7},'Os': 'windows'}
print(employee)
print(employee['name'])
print(employee['name']['Language'])


for key, value in employee.items():
    print("key: {0}, value: {1}".format(key, value))


numbers =  {
5 : 'five'
3 : 'three'
1 : 'one'
2 : 'two'
4 : 'four'
}
