#! /bin/bash
# save as to /usr/loca/bin/git

# echo git "$@" >> /mnt/c/Users/radekzikmund/git.log

# if under windows
if pwd | grep /mnt/c > /dev/null; then

    # if invocation contains any of the expensive commands, then use the win version
    # commands=( describe log update-index version ls-files diff symbolic-ref config show status clone push pull rebase rerere fetch add reset )
    # l2=" ${commands[*]} "                    # add framing blanks
    # for item in $@; do
    # if [[ $l2 =~ " $item " ]] ; then    # use $item as regexp
    #     # command found -> invoke in windows
    #     exec git.exe "$@"
    # fi
    # done

    commands=( rev-parse commit )
    l2=" ${commands[*]} "                    # add framing blanks
    for item in $@; do
    if [[ $l2 =~ " $item " ]] ; then    # use $item as regexp
        # command found -> invoke in linux
        exec /usr/sbin/git "$@"
    fi
    done

    exec git.exe "$@"
fi

# otherwise always use Linux executable
exec /usr/sbin/git "$@"
