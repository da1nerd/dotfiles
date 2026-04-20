#!/bin/sh

EXIT_CODE=0

repo=$( git rev-parse --show-toplevel )
hook_type=$( basename $0 )
hooks=~/.dotfiles/git/hooks

echo "Executing $hook_type hook(s)" >&2

for hook in $hooks/*.$hook_type; do
	if [ -e "${hook}" ]
	then
		echo "" >&2
		echo "Executing ${hook}" >&2
		${hook} >&2
		EXIT_CODE=$((${EXIT_CODE} + $?))
	fi
done

if [ ${EXIT_CODE} -ne 0 ]; then
	echo "" >&2
	echo "Commit Failed." >&2
fi

exit $((${EXIT_CODE}))
