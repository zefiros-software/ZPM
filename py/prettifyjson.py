from io import StringIO
import json, sys
pretty_json = json.dumps(json.load(StringIO(sys.argv[1])), sort_keys=True, indent=4)
sys.stdout.write(pretty_json)