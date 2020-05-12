# ZSH scripts

## Enable ZSH on server

Make sure your bash is zsh

### Install packages

```bash
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
sh -c "curl https://raw.githubusercontent.com/mrowa44/emojify/master/emojify -o ~/bin/emojify && chmod +x ~/bin/emojify"
```

Add this to you `~/.zshrc`:

```bash
export ZPLUG_HOME=~/.zplug
# Check if zplug is installed
if [[ ! -d $ZPLUG_HOME ]]; then
    git clone https://github.com/zplug/zplug $ZPLUG_HOME
    source $ZPLUG_HOME/init.zsh && zplug update --self
fi
source $ZPLUG_HOME/init.zsh

export ZSH_PLUGINS_ALIAS_TIPS_TEXT='💡 '

# zplug plugins
zplug "djui/alias-tips"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"
zplug "supercrabtree/k"
zplug "jonnitto/zsh", from:github, defer:3
zplug "mafredri/zsh-async", from:github
zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme

# zplug check returns true if all packages are installed
# Therefore, when it returns false, run zplug install
zplug check || zplug install

zplug load
```
