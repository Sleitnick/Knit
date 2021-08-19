import re
import sys

with open("CHANGELOG.md") as changelog_file:
	changelog = changelog_file.read()
	index = changelog.find("\n## ")
	log = changelog[:index].strip()
	sys.stdout.write(log)
