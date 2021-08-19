import sys

def get_last_changelog_entry(filename):
	with open(filename) as changelog_file:
		changelog = changelog_file.read()
		index = changelog.find("\n## ")
		log = changelog[:index].strip()
		sys.stdout.write(log)

if __name__ == "__main__":
	filename = sys.argv[1]
	get_last_changelog_entry(filename)
