SSH_ENV="$HOME/.ssh/environment"
editor='mvim'
workspaces="$HOME/workspace"

function edit
{
  $editor $*
}

# start the ssh-agent
function start_agent {
  echo "Initializing new SSH agent..."
  # spawn ssh-agent
  ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
  echo succeeded
  chmod 600 "$SSH_ENV"
  . "$SSH_ENV" > /dev/null
  ssh-add "$HOME/.ssh/mobi-top"
  ssh-add "$HOME/.ssh/id_rsa"
}

# test for identities
function test_identities {
  # test whether standard identities have been added to the agent already
  ssh-add -l | grep "The agent has no identities" > /dev/null
  if [ $? -eq 0 ]; then
    echo calling ssh-add
    ssh-add "$HOME/.ssh/mobi-top"
    ssh-add
    # $SSH_AUTH_SOCK broken so we start a new proper agent
    if [ $? -eq 2 ];then
      start_agent
    fi
  fi
}

# check for running ssh-agent with proper $SSH_AGENT_PID
if [ -n "$SSH_AGENT_PID" ]; then
  ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
  if [ $? -eq 0 ]; then
    test_identities
  fi
# if $SSH_AGENT_PID is not properly set, we might be able to load one from
# $SSH_ENV
else
  if [ -f "$SSH_ENV" ]; then
    . "$SSH_ENV" > /dev/null
  fi
  ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
  if [ $? -eq 0 ]; then
    test_identities
  else
    start_agent
  fi
fi


#
# Prompt Customizations
#
RED="\[\033[0;31m\]"
YELLOW="\[\033[0;33m\]"
GREEN="\[\033[0;32m\]"
GRAY="\[\033[1;30m\]"
EMPTY="\[\033[0;37m\]"

LIGHTBLUE="\[\033[38;5;111m\]"
LIGHTRED="\[\033[38;5;172m\]"
LIGHTYELLOW="\[\033[38;5;229m\]"
CONTINUE="\[\033[38;5;242m\]"
DARKGRAY="\[\033[38;5;247m\]"

function parse_git_branch
{
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

scm_ps1() {
    local s=
    if [[ -d ".svn" ]] ; then
        s=\($(svn info | sed -n -e '/^Revision: \([0-9]*\).*$/s//\1/p' )\)
    else
        s=$(parse_git_branch "(%s)")
    fi

    echo -n "$s"
}

# [hh:mm] username@host (git branch || svn revision) ~/working/directory
# $
# [hh:mm] username@host (git branch || svn revision) ~/working/directory
# $
# Pretty ugly hack for msys... need to figure out how to determine if my
# console is 256 color capable
if [ $OSTYPE = 'msys' ]; then
  PS1="$GREEN[\$(date +%H:%M)] \u@\h $RED\$(scm_ps1) $YELLOW\w \n$EMPTY\$ $GRAY"
  PS2="$GRAY> $GRAY"
else
  PS1="$LIGHTBLUE[\$(date +%H:%M)] \u@\h $LIGHTRED\$(scm_ps1) $LIGHTYELLOW\w \n$EMPTY\$ $DARKGRAY"
  PS2="$CONTINUE> "
fi
