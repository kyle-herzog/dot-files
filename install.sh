uname=`uname -s`
w_info_af='6'
w_complete_af='2'
w_error_af='1'

function link_windows
{
  echo "install files for windows"
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

function initialize_submodules
{
  w_info -n "Initializing submodules..."
  pushd "$script_location"
  out_null "git submodule update --init --recursive"
  popd
  w_complete "done"
}

function install_vim_settings
{
  w_info -n "Installing vim..."
  link_file "$script_location/vim/.vimrc" "${HOME}/.vimrc"
  link_file "$script_location/vim/vimfiles" "${HOME}/.vim"
  link_file "$script_location/vim/vimfiles/bundle/pathogen/autoload" "${HOME}/.vim/autoload"
  w_complete "done"
}

function install_git_settings
{
  w_info "Installing git settings"
  git_config="$script_location/git/.gitconfig.original"
  custom_git_config="$script_location/git/.gitconfig"

  if [ -e $custom_git_config ]; then
    rm $custom_git_config
  fi

  cp $git_config $custom_git_config

  w_info "What is the user.name for git?"
  read -r git_user_name

  w_info "What is the user.email for git?"
  read -r git_user_email

  replace_file_string $custom_git_config "<user.name>" "$git_user_name"
  replace_file_string $custom_git_config "<user.email>" "$git_user_email"

  link_file $custom_git_config "${HOME}/.gitconfig"
  w_complete "done"
}

script_location=$(get_script_directory)

initialize_submodules
install_vim_settings
install_git_settings
