#!/bin/bash

# ## FUNCTIONS # ##
# ## Basic function to prompt the user with a yes/no question to proceed
function ask_yes_or_no() {
  read -p "$1 [Y\n]: "
  case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
    n|no)
      unset NAME
      unset HOSTNAME
      unset DNSNAME
      unset PROFILE
      unset INTERFACE
      unset MACADDRESS
      unset IPADDRESS
      unset GATEWAY
      unset NETMASK
      echo "no"
    ;;
    *) echo "yes"
    ;;
  esac
}

function collect_data() {
  # ## Gather information: node name, environment to put the node in, etc.
  echo -n 'Node to Bootstrap: '
  read bhost
  echo
  echo '-------------------'
  echo 'Pick an Environment'
  echo '-------------------'
  select CENV in `knife environment list`; do
    echo
    echo '----------------------------------------'
    echo 'Given Node name:    '$bhost
    echo 'Chosen environment: '$CENV
    echo '----------------------------------------'
    echo
    break
  done

  if [[ "no" == $(ask_yes_or_no "Is this the correct node name and environment?") ]]
   then
    echo
    echo
    echo "Please wait .... starting over ...."
    echo
    sleep 2
    exec "$0" "$@"
  fi
}

function bootstrap_node() {
  echo
  echo
  echo '--------------------------------------------------'
  echo "----- Boostrapping node $bhost "
  echo '--------------------------------------------------'
  echo

  # ## Bootstrap the node to the baseline role
  knife bootstrap $bhost -N $bhost --sudo -x svc-chef --sudo -E "$CENV" -r 'role[baseline]' --bootstrap-version 13.10.4

  echo
  echo '----- Set the node run list -----'
  echo
  # ## Add the vault and ad_member_prod roles to the node's run list
  knife node run_list add $bhost 'role[vault]'

  echo
  echo '----- Update the Chef Vault -----'
  echo
  # ## Update the Chef Vault so it knows about this new node
  knife vault refresh nerdcave users -M client

  echo
  echo '----- Start the initial Chef Client run -----'
  echo
  # ## Kick off a Chef Client run to complete the configuration
  knife ssh "name:$bhost" -x svc-chef 'sudo chef-client' -a hostname

  echo
  echo

  echo '--------------------------------------------------'
  echo "----- Bootstrapping of node $bhost completed "
  echo '--------------------------------------------------'

  echo
  echo
}

# ## MAIN BODY # ##
clear

echo
echo

collect_data
bootstrap_node
