# Instructions
Please take a look at all of the allowed commands listed in .claude/settings.local.json then sort the allowed commands by tool type: Bash, Read, etc.

Within commands for a specific tool, commands that use the same command line tool should be next to each other. i.e. Bash(aws ecr describe-images:*) should be next to other commands that start with Bash(aws...), and Bash (./tf ... ) should be next to all other Bash(./tf..) and Bash(terraform ...) commands.

## Important
Dont remove or edit any commands just sort them in this way 