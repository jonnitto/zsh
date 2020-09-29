_flow() {
    if _flow_is_inside_base_distribution; then

        local startDirectory=$(pwd)
        while [ ! -f flow ]; do
            builtin cd ..
        done
        if (($CURRENT > 2)); then
            CURRENT=$CURRENT-1
            local cmd=${words[2]}
            shift words

            _flow_subcommand
        else
            _flow_main_commands
        fi
        builtin cd $startDirectory
    fi
}
compdef _flow flow

_flow_main_commands() {
    if [ ! $ZPLUG_HOME ]; then
        _msgError "\$ZPLUG_HOME" "is not defined"
        return 1
    fi
    if [ ! -f Data/Temporary/Development/.flow-autocompletion-maincommands ]; then
        mkdir -p Data/Temporary/Development/
        ./flow help | grep "^[* ][ ]" | php $ZPLUG_HOME/repos/jonnitto/zsh/src/_flow.php >Data/Temporary/Development/.flow-autocompletion-maincommands
    fi

    # fills up cmdlist variable
    eval "$(cat Data/Temporary/Development/.flow-autocompletion-maincommands)"

    _describe 'flow command' cmdlist
}

_flow_subcommand() {
    if [ ! -f Data/Temporary/Development/.flow-autocompletion-command-$cmd ]; then
        ./flow help $cmd >Data/Temporary/Development/.flow-autocompletion-command-$cmd
    fi

    compadd -x "$(cat Data/Temporary/Development/.flow-autocompletion-command-$cmd)"
}

flow() {
    if _flow_is_inside_base_distribution; then
    else
        _msgError "Flow not found inside a parent of current directory"
        return 1
    fi

    local startDirectory=$(pwd)
    while [ ! -f flow ]; do
        builtin cd ..
    done
    php -d memory_limit=-1 ./flow $@
    local flowExitCode=$?
    builtin cd $startDirectory
    return $flowExitCode
}
