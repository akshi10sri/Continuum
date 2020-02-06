'''
import os
import re

for root,dirname,filename in os.walk(os.getcwd()):
    pth_build=""
    if os.path.isfile(root+"/__init__.py"):
        for i in filename:
            if i <> "__init__.py" and i <> "__init__.pyc" :
                if i.split('.')[1] == "py":
                    slot = list(set(root.split('\\')) -set(os.getcwd().split('\\')))
                    pth_build = slot[0]
                    del slot[0]
                    for j in slot:
                        pth_build = pth_build+"."+j
                    print pth_build +"."+ i.split('.')[0]
'''
import pkgutil
import os
modualList = []
for importer, modname, ispkg in pkgutil.iter_modules(os.__path__):
    modualList.append(modname)                    