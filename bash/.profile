SSH_ENV="$HOME/.ssh/environment"
editor='mvim'
workspaces="$HOME/workspaces"
uname=`uname -s`

w_info_af='6'
w_complete_af='2'
w_error_af='1'

function link_windows
{
  if [ -d $1 ]; then
    $switch = "J"
  fi
  if [ -f $1 ]; then
    $switch = "D"
  fi
  cmd /C "MKLINK /$switch" $1 $2
}

function link_mac
{
  ln -sfv $1 $2
}

function link_file
{
  if [[ "$uname" = MINGW* || "$uname" = CYGWIN* ]]; then
    link_windows $* &> /dev/null
    return
  else
    link_mac $* &> /dev/null
  fi
}

function out_null
{
  $1 &> /dev/null
}

function w_colors
{
  numargs=$#
  tput setaf $1
  if [[ $numargs -ge 3 ]]; then
    echo $2 "$3"
  else
    echo "$2"
  fi
  unset numargs
  tput sgr0
}

function w_info
{
  numargs=$#
  if [[ $numargs -ge 2 ]]; then
    w_colors $w_info_af $1 "$2"
  else
    w_colors $w_info_af "$1"
  fi
  unset numargs
}

function w_complete
{
  numargs=$#
  if [[ $numargs -ge 2 ]]; then
    w_colors $w_complete_af $1 "$2"
  else
    w_colors $w_complete_af "$1"
  fi
  unset numargs
}

function w_error
{
  numargs=$#
  if [[ $numargs -ge 2 ]]; then
    w_colors $w_error_af $1 "$2"
  else
    w_colors $w_error_af "$1"
  fi
  unset numargs
}

function w_complete
{
  w_colors $w_complete_af $*
}

function replace_file_string
{
  temp_file="$script_location/.temp"
  sed "s/$2/$3/g" $1 > $temp_file
  mv $temp_file $1
}

function get_script_directory
{
  relative_path="$(dirname "$0")"
  out_null "pushd $relative_path"
  full_path=$PWD
  out_null "popd"
  echo $full_path
}


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

function initialize_ssh
{
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
}

function parse_git_branch
{
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function generate_vcs_information
{
    local s=
    if [[ -d ".svn" ]] ; then
        s=\($(svn info | sed -n -e '/^Revision: \([0-9]*\).*$/s//\1/p' )\)
    else
        s=$(parse_git_branch "(%s)")
    fi

    echo -n "$s"
}

function set_shell_colors
{
  if [ $OSTYPE = 'msys' ]; then
    shell_date_color="\[\033[0;31m\]"
    shell_yelloy="\[\033[0;33m\]"
    shell_gray="\[\033[1;30m\]"
  else
    shell_date_color="\[\033[38;5;111m\]"
    shell_yellow="\[\033[38;5;229m\]"
    shell_gray="\[\033[38;5;247m\]"
  fi
  shell_green="\[\033[0;32m\]"
  shell_empty="\[\033[0;37m\]"
  shell_red="\[\033[38;5;172m\]"
}

function generate_shell_information
{
  PS1="$shell_date_color[\$(date +%H:%M)] \u@\h $shell_red\$(generate_vcs_information) $shell_yellow\w \n$shell_empty\$ $shell_gray"
  PS2="$shell_gray> $shell_gray"
}

set_shell_colors
generate_shell_information
initialize_ssh
