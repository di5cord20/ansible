# Ansible VM/LXC Onboarding Script

This repository helps you onboard new Debian/Ubuntu VMs or LXCs to your Ansible automation environment with minimal manual steps.

---

## 🚀 What This Script Does

The `add_new_host.sh` script:

* Prompts you for the VM name, IP address, and Ansible SSH user (default: `ubuntu`)
* Asks whether this VM should be managed with the Komodo agent
* Copies your Ansible SSH public key to the target VM
* Backs up and updates your Ansible inventory (`inventory/inventory.yml`)
* Tags the VM (`komodo` or `base`) and adds metadata
* Pings the VM with Ansible to verify connectivity
* Optionally runs one of your Ansible playbooks

---

## 🔧 Prerequisites

* Ansible must be installed on your control server (e.g., `192.168.96.75`)
* Your Ansible control node must contain an SSH key pair:

  * `~/.ssh/ansible`
  * `~/.ssh/ansible.pub`
* Your static Ansible inventory should exist at `./inventory/inventory.yml`

---

## 🪪 Step 1: Ensure SSH Key Is Set Up

If you haven't already created the Ansible SSH key:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible
```

Do **not** enter a passphrase.

---

## 📁 Step 2: Run the Script

Run the onboarding script:

```bash
bash add_new_host.sh
```

You'll be prompted to:

* Enter the VM name (e.g., `newvm01`)
* Enter the VM IP address (e.g., `192.168.96.110`)
* Confirm or override the Ansible SSH user (default: `ubuntu`)
* Choose whether to install the Komodo agent

The script will:

* Automatically copy your SSH key to the VM
* Update and back up your Ansible inventory file
* Add the host to the appropriate group (`komodo_hosts` or `general_hosts`)
* Add metadata like `tags` and `komodo_managed` status

---

## 🔁 Inventory Format Example

```yaml
komodo_hosts:
  hosts:
    newvm01:
      ansible_host: 192.168.96.110
      komodo_managed: true
      tags: [komodo]

general_hosts:
  hosts:
    backupnode01:
      ansible_host: 192.168.96.120
      komodo_managed: false
      tags: [base]

  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/ansible
```

---

## ✅ Final Step: Run a Playbook

Once the VM is reachable, you'll be asked if you'd like to run one of your Ansible playbooks (found in `~/playbooks/`).

Example playbook command the script will run:

```bash
ansible-playbook -i inventory/inventory.yml playbooks/common.yml --limit newvm01
```

---

## ✨ Notes

* The inventory is automatically backed up before any changes.
* You can rerun the script to onboard additional VMs anytime.
* Ensure all playbooks you want to run are stored in `~/playbooks/`.

---

## 🛠️ Coming Soon (Future Enhancements)

* Auto-tagging based on hostname patterns
* Metadata extraction from LXC config
* Dynamic inventory integration

---

Happy automating! ⚙️
