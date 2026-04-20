#!/bin/sh

EXIT_CODE=0

repo=$( git rev-parse --show-toplevel )
hook_type=$( basename $0 )
hooks=~/.dotfiles/git/hooks

echo "Executing $hook_type hook(s)"

for hook in $hooks/*.$hook_type; do
	if [ -e "${hook}" ]
	then
		echo ""
		echo "Executing ${hook}"
		${hook}
		EXIT_CODE=$((${EXIT_CODE} + $?))
	fi
done

if [ ${EXIT_CODE} -ne 0 ]; then
	echo ""
	echo "Commit Failed."
fi

exit $((${EXIT_CODE}))
