# Deployer basic command completion
_deployer_get_command_list() {
    dep --no-ansi | sed "1,/Available commands/d" | awk '/^ +[a-z]+/ { print $1 }'
}

_deployer_get_servers() {
    cat deploy.yml | awk '/^[a-zA-Z]+/ { print $1 }' | tr ":" " "
}

_dep() {
    if [ "$CURRENT" = "3" ]; then
        compadd $(_deployer_get_servers)
    else
        compadd $(_deployer_get_command_list)
    fi
}

compdef _dep dep
