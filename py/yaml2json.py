from yaml import load
from json import dumps
from sys import argv

with open(argv[1], 'r') as stream:
    print(dumps(load(stream), sort_keys=True, indent=4))