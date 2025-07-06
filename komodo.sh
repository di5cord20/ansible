# add to .bashrc 

komodo() {
  local action="$1"
  local version="$2"

  if [[ "$action" == "install" ]]; then
    if [[ -n "$version" ]]; then
      ansible-playbook -i inventory/komodo.yaml playbooks/komodo.yml \
        -e "komodo_version=$version" \
        --vault-password-file .vault_pass
    else
      ansible-playbook -i inventory/komodo.yaml playbooks/komodo.yml \
        --vault-password-file .vault_pass
    fi

  elif [[ "$action" == "update" ]]; then
    if [[ -z "$version" ]]; then
      echo "Usage: komodo update <version>"
      return 1
    fi
    ansible-playbook -i inventory/komodo.yaml playbooks/komodo.yml \
      -e "komodo_action=update" \
      -e "komodo_version=$version" \
      --vault-password-file .vault_pass

  elif [[ "$action" == "uninstall" ]]; then
    ansible-playbook -i inventory/komodo.yaml playbooks/komodo.yml \
      -e "komodo_action=uninstall" \
      -e "komodo_delete_user=true" \
      --vault-password-file .vault_pass

  else
    echo "Usage:"
    echo "  komodo install [version]     # install (optionally specify version)"
    echo "  komodo update <version>      # update to specified version"
    echo "  komodo uninstall             # uninstall everything"
    return 1
  fi
}
