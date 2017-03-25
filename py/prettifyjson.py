import json, sys 
with open(sys.argv[1], 'r') as stream:
    pretty_json = json.dumps(json.load(stream), sort_keys=True, indent=4)

with open(sys.argv[1], 'w') as stream:
    stream.write(pretty_json)