#!/bin/bash

INVENTORY_FILE="./inventory/inventory.yml"
SSH_KEY_PRIVATE="$HOME/.ssh/ansible"
SSH_KEY_PUBLIC="$HOME/.ssh/ansible.pub"

echo "📁 Add a new VM/LXC to your Ansible inventory"
echo "---------------------------------------------"

# Step 1: Get VM name
while true; do
  read -rp "Enter new VM name (e.g. newvm01): " NEW_VM_NAME
  [[ -n "$NEW_VM_NAME" ]] && break
  echo "❌ VM name cannot be empty."
done

# Step 2: Get VM IP
while true; do
  read -rp "Enter new VM IP address (e.g. 192.168.96.110): " NEW_VM_IP
  [[ "$NEW_VM_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && break
  echo "❌ Invalid IP address format."
done

# Step 3: Ask for Ansible SSH user
read -rp "Enter SSH user for Ansible [ubuntu]: " ANSIBLE_USER
ANSIBLE_USER=${ANSIBLE_USER:-ubuntu}

# Step 4: Komodo menu
echo "🔧 Should Komodo be installed on this VM?"
select yn in "Yes" "No"; do
  case $yn in
    Yes ) KOMODO_MANAGED=true; HOST_GROUP="komodo_hosts"; TAGS="komodo"; break;;
    No ) KOMODO_MANAGED=false; HOST_GROUP="general_hosts"; TAGS="base"; break;;
    * ) echo "Please select 1 or 2.";;
  esac
done

# Step 5: SSH key copy
if [[ ! -f "$SSH_KEY_PRIVATE" || ! -f "$SSH_KEY_PUBLIC" ]]; then
  echo "❌ SSH keys $SSH_KEY_PRIVATE or $SSH_KEY_PUBLIC not found."
  exit 1
fi

echo "🔐 Copying SSH key to $ANSIBLE_USER@$NEW_VM_IP..."
ssh-copy-id -i "$SSH_KEY_PUBLIC" "$ANSIBLE_USER@$NEW_VM_IP"
[[ $? -ne 0 ]] && echo "❌ Failed to copy SSH key. Exiting." && exit 1

# Step 6: Inventory backup + host group insertion
if [[ ! -f "$INVENTORY_FILE" ]]; then
  echo "❌ Inventory file $INVENTORY_FILE not found."
  exit 1
fi

BACKUP_FILE="${INVENTORY_FILE}.$(date +%Y%m%d%H%M%S).bak"
echo "📁 Backing up inventory to $BACKUP_FILE..."
cp "$INVENTORY_FILE" "$BACKUP_FILE"

# Ensure group exists
if ! grep -q "^$HOST_GROUP:" "$INVENTORY_FILE"; then
  echo -e "\n$HOST_GROUP:\n  hosts:" >> "$INVENTORY_FILE"
fi

# Add host if not already present
if grep -q "^ *$NEW_VM_NAME:" "$INVENTORY_FILE"; then
  echo "ℹ️ Host $NEW_VM_NAME already exists in inventory. Skipping update."
else
  echo "✍ Adding $NEW_VM_NAME to group $HOST_GROUP in inventory..."
  sed -i "/^$HOST_GROUP:/,/^ *vars:/ {
    /  hosts:/a\    $NEW_VM_NAME:\n      ansible_host: $NEW_VM_IP\n      komodo_managed: $KOMODO_MANAGED\n      tags: [$TAGS]"
  }" "$INVENTORY_FILE"
  echo "✅ Host added successfully."
fi

# Ensure global vars exist
if ! grep -q "^  vars:" "$INVENTORY_FILE"; then
  echo -e "  vars:\n    ansible_user: $ANSIBLE_USER\n    ansible_ssh_private_key_file: $SSH_KEY_PRIVATE" >> "$INVENTORY_FILE"
fi

# Step 7: Ping test
echo
echo "📱 Testing connectivity to $NEW_VM_NAME..."
ansible -i "$INVENTORY_FILE" "$NEW_VM_NAME" -m ping
if [[ $? -ne 0 ]]; then
  echo "❌ Ansible ping failed. Please troubleshoot connectivity or SSH access."
  exit 1
fi

# Step 8: Offer to run a playbook
echo
echo "✅ Ping successful!"
echo "📦 Available playbooks in ~/playbooks:"
select pb in $(ls ~/playbooks/*.yml 2>/dev/null); do
  if [[ -n "$pb" ]]; then
    echo "🚀 Run playbook '$pb' on $NEW_VM_NAME?"
    select confirm in "Yes" "No"; do
      case $confirm in
        Yes )
          ansible-playbook -i "$INVENTORY_FILE" "$pb" --limit "$NEW_VM_NAME"
          break 2
          ;;
        No )
          echo "✅ Done. Playbook not run."
          break 2
          ;;
        * ) echo "Please select 1 or 2.";;
      esac
    done
  else
    echo "❌ No playbooks found in ~/playbooks"
    break
  fi
done
