# Deployer basic command completion
_deployer_get_command_list() {
    dep --no-ansi | sed "1,/Available commands/d" | awk '/^(  )/ { print $1}'
}

_deployer_get_servers() {
    cat deploy.yaml | awk '/^[a-zA-Z]+/ { print $1 }' | tr ":" " "
}

_deployer_get_stages() {
    cat deploy.yaml | grep ' stage:' | awk '{ print $2 }'
}

_dep() {
    if [ "$CURRENT" = "3" ]; then
        compadd $(_deployer_get_stages)
    else
        compadd $(_deployer_get_command_list)
    fi
}

compdef _dep dep
