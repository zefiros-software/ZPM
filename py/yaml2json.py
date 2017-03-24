import yaml, json, sys 
with open(sys.argv[1], 'r') as stream:
    sys.stdout.write(json.dumps(yaml.load(stream), sort_keys=True, indent=4))