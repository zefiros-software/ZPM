import yaml, json, sys
sys.stdout.write(json.dumps(yaml.load(sys.stdin), sort_keys=True, indent=2))