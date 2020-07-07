#!/usr/bin/sh

deploy () {
	mkdocs gh-deploy
}

watch () {
	python -mwebbrowser http://localhost:8000
	mkdocs serve
}

build () {
	mkdocs build
}

help () {
	echo "
Useage: $(basename $0) <command>

Commands:
| deploy
| watch
| build
| help"
}

if [ $# -eq 0 ]
then
	echo "Error: No arguments supplied"
	help
	exit 1
fi

if [ $1 = "deploy" ]
then
	deploy
elif [ $1 = "watch" ]
then
	watch
elif [ $1 = "build" ]
then
	build
elif [ $1 = "help" ]
then
	help
else
	echo "Error: Command not recognized"
	help
	exit 1
fi