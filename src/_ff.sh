_ff() {
    local -a cmdlist
    eval $(ff commands)
    _describe 'command' cmdlist
}
compdef _ff ff

ff() {
    if _flow_is_inside_base_distribution; then
    else
        _msgError "Flow not found inside a parent of current directory"
        return 1
    fi

    local startDirectory=$(pwd)
    while [ ! -f flow ]; do
        builtin cd ..
    done

    typeset -A flowCommands;
    typeset -A shellCommands;
    typeset -A functionCommands;
    flowCommands=(
        flushCache 'flow:cache:flush'
        flushContentCache 'cache:flushone --identifier Neos_Fusion_Content'
        warmup 'flow:cache:warmup'
        publishResource 'resource:publish'
        migratedb 'doctrine:migrate'
        prune 'site:prune'
        import 'site:import --package-key $(basename Packages/Sites/*)'
        export 'site:export --package-key $(basename Packages/Sites/*) --tidy'
        createAdmin 'user:create --roles Administrator'
        run 'server:run --host neos.local'
    );
    shellCommands=(
        setuppwd 'cat Data/SetupPassword.txt'
    );
    functionCommands=(
        recreateThumbnails 'Remove thumbnails, publish resources, create and render thumbnails'
        repairpermission 'Adjust file permissions for CLI and web server access'
        deployContext 'Set the FLOW_CONTEXT by reading deploy.yaml'
        switchContext 'Switch between Production and Development context'
    );

    if [[ $1 == 'commands' ]]; then
        printf "cmdlist=("
        for key val in ${(kv)flowCommands}; do
            printf "\"$key:$val\" "
        done
        for key val in ${(kv)shellCommands}; do
            printf "\"$key:$val\" "
        done
        for key val in ${(kv)functionCommands}; do
            printf "\"$key:$val\" "
        done
        echo ")";
        builtin cd $startDirectory
        return 0;
    fi

    if [ $# -eq 0 ]; then
        for key val in ${(kv)flowCommands}; do
            printf "\n${fg[cyan]}%20s${reset_color} %-70s" \
            $key $val
        done
        for key val in ${(kv)shellCommands}; do
            printf "\n${fg[cyan]}%20s${reset_color} %-70s" \
            $key $val
        done
        for key val in ${(kv)functionCommands}; do
            printf "\n${fg[cyan]}%20s${reset_color} %-70s" \
            $key $val
        done
        echo ""
        builtin cd $startDirectory
        return 0;
    fi

    local cmd=$1;
    shift;
    if [ ${flowCommands[$cmd]} ]; then
        echo "./flow ${flowCommands[$cmd]}" | bash
        local exitCode=$?
        builtin cd $startDirectory
        return $exitCode
    fi
    if [ ${shellCommands[$cmd]} ]; then
        echo "${shellCommands[$cmd]}" | bash
        local exitCode=$?
        builtin cd $startDirectory
        return $exitCode
    fi
    if [[ $cmd == 'recreateThumbnails' ]]; then
        _msgInfo "Recreate thumbnails, this might take a while ..."
        ./flow media:clearthumbnails
        ./flow resource:publish
        ./flow media:createthumbnails
        ./flow media:renderthumbnails
        _msgSuccess "Done"
        local exitCode=$?
        builtin cd $startDirectory
        return $exitCode
    fi
    if [[ $cmd == 'repairpermission' ]]; then
        _msgInfo "Setting file permissions per file, this might take a while ..."
        local USER=$(whoami)
        local GROUP=$(id -g -n)
        chown -R $USER:$GROUP .
        find . -type d -exec chmod 775 {} \;
        find . -type f \! \( -name commit-msg -or -name '*.sh' \) -exec chmod 664 {} \;
        chmod 770 flow
        chmod 755 Web
        chmod 644 Web/index.php
        chmod 644 Web/.htaccess
        chown -R $USER:$GROUP Web/_Resources
        chmod 775 Web/_Resources
        _msgSuccess "Done"
        builtin cd $startDirectory
        return 0
    fi
    if [[ $cmd == 'deployContext' ]]; then
        local newContext='Production'
        if [ -f deploy.yaml ]; then
            flowContext=$(cat deploy.yaml | grep ' flow_context' | awk '{print $2}')
            subContext=$(cat deploy.yaml | grep ' sub_context' | awk '{print $2}')
            if [ $flowContext ]
                then newContext=$flowContext;
            elif [ $subContext ]
                then newContext="Production/$subContext";
            else
                newContext='Production/Live';
            fi
        fi
        export FLOW_CONTEXT=$newContext
        _msgInfo "Set Flow Context to" $FLOW_CONTEXT
        builtin cd $startDirectory
        return 0
    fi
    if [[ $cmd == 'switchContext' ]]; then
        if [[ $FLOW_CONTEXT == "Development" ]]
            then 
                ff deployContext
            else
                export FLOW_CONTEXT=Development
                _msgInfo "Set Flow Context to" $FLOW_CONTEXT
        fi
        builtin cd $startDirectory
        return 0
    fi
    local exitCode=$?
    builtin cd $startDirectory
    return $exitCode
}
