_msgInfo() { printf "\n    ${fg[cyan]}${1}${fg[green]} ${2}${reset_color}\n\n"; }
_msgSuccess() { printf "\n    ${fg[green]}${1}${reset_color} ${2}\n\n"; }
_msgError() { printf "\n    ${fg[red]}${1}${reset_color} ${2}\n\n"; }
_available() { command -v $1 >/dev/null 2>&1; }

_flow_is_inside_base_distribution() {
    local startDirectory=$(pwd)
    while [[ ! -f flow ]]; do

        if [[ $(pwd) == "/" ]]; then
            builtin cd $startDirectory
            return 1
        fi
        builtin cd ..
    done
    builtin cd $startDirectory
    return 0
}

_hostname=""
_servername="h"
_session_type="local"

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    _session_type=remote/ssh
else
    case $(ps -o comm= -p $PPID) in
    sshd | */sshd) _session_type=remote/ssh ;;
    esac
fi

case $(hostname -f) in
*.uberspace.de)
    server="Uberspace"
    _hostname="$server "
    _servername="u"
    ;;
*.punkt.de)
    server="PunktDe"
    _hostname="$server "
    _servername="u@\h"
    ;;
*.local) server="Local" ;;
*) server="NONE" ;;
esac

if [ $_session_type = "local" ]; then
    server="Local"
fi

if [ $USER = "beach" ]; then
    server="Beach"
    _servername="u"
fi

## Read ssh key
readKey() {
    echo
    cat ~/.ssh/id_rsa.pub
    echo
}

## Generate ssh key
case $server in
Uberspace | PunktDe)
    generateKey() {
        ssh-keygen -t rsa -b 4096 -C "$(hostname -f)"
        readKey
    }
    ;;
esac

## Set paths
case $server in
Uberspace)
    WEB_ROOT="/var/www/virtual/${USER}"
    NEOS_ROOT="/var/www/virtual/${USER}/Neos"
    NEOS_DEPLOYER="/var/www/virtual/${USER}/Neos/current"
    alias readSQLConfig='cat ~/.my.cnf'
    alias installImgOptimizer='npm install -g jpegtran-bin optipng-bin gifsicle svgo'
    ;;
PunktDe)
    WEB_ROOT="/var/www/"
    NEOS_ROOT="/var/www/Neos/current"
    NEOS_DEPLOYER="/var/www/Neos/current"
    ;;
esac

## go 2 specifc folder funtions

if [ ! -z "$WEB_ROOT" ]; then
    go2www() {
        if [ "$WEB_ROOT" ] && [ -d "$WEB_ROOT" ]; then cd $WEB_ROOT; fi
    }
fi

if [ ! -z "$NEOS_ROOT" ] || [ ! -z "$NEOS_DEPLOYER" ]; then
    go2Neos() {
        if [ "$NEOS_DEPLOYER" ] && [ -d "$NEOS_DEPLOYER" ] && [ -f "$NEOS_DEPLOYER/flow" ]; then
            cd $NEOS_DEPLOYER
        elif [ "$NEOS_ROOT" ] && [ -d "$NEOS_ROOT" ] && [ -f "$NEOS_ROOT/flow" ]; then
            cd $NEOS_ROOT
        elif [ "$WEB_ROOT" ] && [ -f "${WEB_ROOT}/flow" ]; then
            type go2www &>/dev/null && go2www
        fi
    }
fi

## Set context
case $server in
NONE | Local)
    export FLOW_CONTEXT=Development
    ;;
*)
    ff deployContext
    ;;
esac

case $server in
Beach | Local)
    alias runUnitTest='./Packages/Libraries/phpunit/phpunit/phpunit -c Build/BuildEssentials/PhpUnit/UnitTests.xml --colors=always'
    alias runFunctionalTest='./Packages/Libraries/phpunit/phpunit/phpunit -c Build/BuildEssentials/PhpUnit/FunctionalTests.xml --colors=always'
    ;;
esac

case $server in
Uberspace)
    writeNeosSettings() {
        if _flow_is_inside_base_distribution; then
        else
            _msgError "Flow not found inside a parent of current directory"
            return 1
        fi

        local startDirectory=$(pwd)
        while [ ! -f flow ]; do
            builtin cd ..
        done
        _msgInfo "Write configuration file for Neos ..."
        cat >Configuration/Settings.yaml <<__EOF__
Neos:
  Imagine:
    driver: Imagick
  Flow:
    core:
        phpBinaryPathAndFilename: '/usr/bin/php'
      subRequestIniEntries:
        memory_limit: 2048M
    persistence:
      backendOptions:
        driver: pdo_mysql
        dbname: ${USER}
        user: ${USER}
        password: '$(grep -Po -m 1 "password=\K(\S)*" ~/.my.cnf)'
        host: localhost
__EOF__
        _msgInfo "Following configuration was written"
        cat Configuration/Settings.yaml
        echo
        builtin cd $startDirectory
        return 0
    }
    alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --decorate --date=short --color | emojify"
    alias gs='git status'
    ;;
Local)
    alias h='cd ~/'
    alias dev='cd ~/Development'
    alias n='cd ~/Development/Neos.Plugins'
    alias copyKey='_msgSuccess "SSH Key copied to clipboard";pbcopy < ~/.ssh/id_ed25519.pub'
    alias copyRSAKey='_msgSuccess "SSH Key copied to clipboard";pbcopy < ~/.ssh/id_rsa.pub'
    alias startserver='http-server -a localhost -p 8000 -c-1'
    alias installGoogleFonts='_msgSuccess "Install all Google Fonts ...";curl https://raw.githubusercontent.com/qrpike/Web-Font-Load/master/install.sh | sh'
    alias ios='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'
    alias sshConnect='ssh $(basename "$PWD")'
    alias editConnect='code ~/.ssh/config'
    alias yui='yarn upgrade-interactive --latest'
    alias yuiglobal='yarn global upgrade-interactive --latest'
    alias openNeosPlugins='code ~/Development/Neos.Plugins'

    alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --decorate --date=short --color | emojify"
    alias gp='git push origin HEAD'
    alias gd='git diff'
    alias gco='git checkout'
    alias gcb='git copy-branch-name'
    alias gb='git branch'
    alias gs='git status'
    alias ga='git add'
    alias gap='git add -p'
    alias gfr='git stash && git fetch && git rebase && git stash pop'
    neosPluginsDiff() {
        if [ $1 ]; then
            if [ ! -d ~/Development/Neos.Plugins/$1 ]; then
                _msgError $1 "is not available in Neos.Plugins"
                return 1
            fi

            for distributionPackage in DistributionPackages/*; do
                if [ DistributionPackages/$1 = $distributionPackage ]; then
                    ksdiff ~/Development/Neos.Plugins/$1 $distributionPackage
                    return 0
                fi
            done

            for category in Packages/*; do
                for package in ${category}/*; do
                    if [ ${category}/${1} = $package ]; then
                        ksdiff ~/Development/Neos.Plugins/$1 $package
                        return 0
                    fi
                done
            done

            _msgError $1 "was not found"
            return 1
        else
            ksdiff ~/Development/Neos.Plugins Packages/Plugins Packages/Carbon
            return 0
        fi
    }
    gc() {
        if [ -z ${1+x} ]; then
            _msgError "Please set a commit message"
        else
            git commit -m "$1"
        fi
    }
    gca() {
        if [ -z ${1+x} ]; then
            git commit -a
        else
            git commit -a -m "$1"
        fi
    }
    deleteGitTag() {
        if [ -z ${1+x} ]; then
            _msgError "Please set a tag as first argument"
        else
            _msgError "Delete Git tag" "'$1'"
            git tag -d $1
            git push origin :refs/tags/$1
            echo
        fi
    }

    sshList() {
        # list hosts defined in ssh config

        awk '$1 ~ /Host$/ {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config
    }

    # With the command `NeosProject` you get the site package folder and available folders definded in `ADDITIONAL_FOLDER`
    # With `codeProject` you open your project in Visual Studio Code
    # With `atomProject` you open your project in Atom
    # With `pstormProject` you open your project in PHP Storm
    # To disable the fallback (open current folder), change the fallback variable to ""

    NeosProject() {
        # Places where site packages could are stored
        local SITE_FOLDER=("DistributionPackages" "src" ".src" "Packages/Sites")

        # Additional folder to open
        local ADDITIONAL_FOLDER=("Packages/Carbon" "Packages/Plugins" "Web")

        local FOLDER_ARRAY=()

        local fallback="."

        # Get the site folder
        for f in "${SITE_FOLDER[@]}"; do
            if [ -d "$f" ] && [[ ${#FOLDER_ARRAY[@]} == 0 ]]; then
                FOLDER_ARRAY+=("${f}/$([ $(echo ${f}/* | wc -w) = 1 ] && basename ${f}/*)")
            fi
        done

        # Get additional folder
        for f in "${ADDITIONAL_FOLDER[@]}"; do
            if [ -d "${f}" ]; then
                FOLDER_ARRAY+=($f)
            fi
        done

        # Fallback
        if [ -n "$fallback" ] && [[ ${#FOLDER_ARRAY[@]} == 0 ]]; then
            FOLDER_ARRAY=($fallback)
        fi
        echo "${FOLDER_ARRAY[@]}"
    }

    codeProject() {
        # If we have a code workspace, open this instead
        if [[ -f *.code-workspace ]]; then
            for f in *.code-workspace; do open "$f"; done
        else
            code $(NeosProject)
        fi
    }

    pstormProject() {
        pstorm $(NeosProject)
    }

    # Generate the DB and the 'Settings.yaml' file
    writeNeosSettings() {
        if _flow_is_inside_base_distribution; then
        else
            _msgError "Flow not found inside a parent of current directory"
            return 1
        fi

        local startDirectory=$(pwd)
        while [ ! -f flow ]; do
            builtin cd ..
        done

        [ $? -ne 0 ] && return 1
        _msgInfo "Write configuration file for Neos ..."
        dbName=$(echo ${PWD##*/} | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' | sed -E 's/[\.-]+/_/g')
        dbName="${dbName}_neos"
        _msgInfo "Create Database" $dbName
        mysql -uroot -proot -e "create database ${dbName}"
        cat >Configuration/Settings.yaml <<__EOF__
Neos:
  Imagine:
    driver: Imagick
  Flow:
    core:
      subRequestIniEntries:
        memory_limit: 2048M
    persistence:
      backendOptions:
        driver: pdo_mysql
        dbname: ${dbName}
        user: root
        password: root
        host: 127.0.0.1
__EOF__

        _msgInfo "Following configuration was written"
        cat Configuration/Settings.yaml
        echo
        builtin cd $startDirectory
        return 0
    }
    ;;
esac

# ================================
#      HELPME
# ================================
helpme() {
    _Headline() {
        if _available $1; then
            _printHeadline $2
        fi
    }

    _printHeadline() {
        printf "\n\n                     ${fg[green]}$1\n----------------------------------------------------------------------------${reset_color}\n"
    }

    _Entry() {
        if _available $1; then
            printf "\n${fg[cyan]}%20s${reset_color} %-50s\n" \
                $1 "$2"
        fi
    }

    _Lines() {
        if _available $1; then
            printf "${fg[cyan]}%20s${reset_color} %-50s\n" \
                "" "$2"
        fi
    }

    _Headline go2 System
    _Entry go2www "Go to the www folder"
    _Entry readKey "Output the ssh public key"
    _Entry copyKey "Copy the ssh public key to the clipboard"
    _Entry generateKey "Create a ssh key and output the public key"
    _Entry startserver "Start local server, listen to port 8000"
    _Entry installGoogleFonts "Install all Google Fonts to your system"
    _Entry ios "Open the iOS Simulator"
    _Entry sshConnect "Open SSH connection based on the folder name"
    _Entry editConnect "Edit the SSH connection presets"
    _Entry deleteGitTag "Delete a git tag and push it to origin"
    _Entry yui "Update the dependencies with yarn"
    _Entry readSQLConfig "Read the SQL configuration"
    _Entry installImgOptimizer "Install jpegtran-bin, optipng-bin,"
    _Lines installImgOptimizer "gifsicle and svgo globally with npm"

    _Headline deleteGitTag Git
    _Entry gl "Output the git log"
    _Entry gp "Push to origin"
    _Entry gd "git diff"
    _Entry gc "Commit with a message"
    _Entry gca "Commit automatically stage files that have been,"
    _Lines gca "modified and deleted but new files you have not"
    _Lines gca "told Git about are not affected"
    _Entry gco "git checkout"
    _Entry gcb "git copy-branch-name"
    _Entry gb "git branch"
    _Entry gs "git status"
    _Entry ga "git add"
    _Entry gap "git add with patch mode"
    _Entry gfr "git stash && git fetch && git rebase && git stash pop"
    _Entry deleteGitTag "Delete a git tag and push it to origin"

    _Headline flowhelp Neos
    _Entry go2Neos "Go to the Neos Folder"
    _Entry writeNeosSettings "Generate the 'Settings.yaml' file"
    printf "\n\n\n"
    unset _Headline
    unset __printHeadline
    unset _Entry
    unset _Lines
}

# ================================
#    SET PROMT AND ALIAS
# ================================

alias df='df -h'
alias du='du -h --max-depth=1'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias head='head -n 50'
alias tail='tail -n 50'

alias ..='cd ..'         # Go up one directory
alias cd..='cd ..'       # Common misspelling for going up one directory
alias ...='cd ../..'     # Go up two directories
alias ....='cd ../../..' # Go up three directories
alias -- -='cd -'        # Go back

# Shell History
alias h='history'

# Display whatever file is regular file or folder
catt() {
    for i in "$@"; do
        if [ -d "$i" ]; then
            ls "$i"
        else
            cat "$i"
        fi
    done
}

# List directory contents
if ls --color -d . &>/dev/null; then
    alias ls="ls --color=auto"
elif ls -G -d . &>/dev/null; then
    alias ls='ls -G' # Compact view, show colors
fi

alias sl=ls
alias l='ls -a'
alias ll='ls -lh'
alias la='ls -lsha'
alias l1='ls -1'

alias q='exit'
alias c='clear'

alias cu='composer update'
alias ci='composer install'
alias co='composer outdated'
alias cr='composer require'
alias crnu='composer require --no-update'
alias flowCreateAdmin='flow user:create --roles Administrator'

function commitUpdate() {
    git add *.lock
    git commit -m ":arrow_up: Update dependencies"
    git push
}
