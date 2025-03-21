#! /bin/sh


while getopts p: flag
do
    case "${flag}" in
        p) playbook=${OPTARG};;
#        a) age=${OPTARG};;
#        f) fullname=${OPTARG};;
    esac
done

# Check if ansible package is installed
if ! yum list installed ansible >/dev/null 2>&1; then
    echo "ansible package is not installed. Installing..."

    # Install ansible package
    yum install -y ansible

    # Make sure NFS is installed
    dnf install -y nfs-utils

    # Grab python version
    # Run the ansible command and capture the output
    ansible_output=$(ansible --version)

    # Extract the Python version using regex
    python_version=$(echo "$ansible_output" | grep -oP  'python version.+\K\((.*?)\)'|tr -d '()')
    echo "$python_version"


    # Install additional dependencies
    curl -sS https://bootstrap.pypa.io/get-pip.py | $python_version
    $python_version -m pip install requests
    $python_version -m pip install NetApp-Lib

    echo "Ansible Installation completed."
else
    echo "ansible package is already installed."
fi


if  ! test -f "$HOME/.ssh/id_rsa"
        # ensure required collections are installed. ansible.windows and ansible.posix are redundant, but purple text isn't a bad thing
        then ansible-galaxy collection install community.windows
        anisble-galaxy collection install microsoft.ad
        ansible-galaxy collection install ansible.windows
        ansible-galaxy collection install ansible.posix
        ansible-galaxy collection install netapp.ontap:22.8.3
        ansible-galaxy collection install ogratwicklcs.realmd_ipa_ad
        pip3 install netapp-ontap
        
        # prep ssh keys
        ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -N ""
        sshpass -p Netapp1! ssh-copy-id -o StrictHostKeyChecking=no 192.168.0.61

        # copy to Windows Hosts
        sshpass -p Netapp1! scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa.pub administrator@demo@dc1.demo.netapp.com:C:\\ProgramData\\ssh\\administrators_authorized_keys
        sshpass -p Netapp1! scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa.pub administrator@demo@jumphost.demo.netapp.com:C:\\ProgramData\\ssh\\administrators_authorized_keys
        sshpass -p Netapp1! ssh -o StrictHostKeyChecking=no administrator@demo@dc1.demo.netapp.com "get-acl C:\\ProgramData\\ssh\\ssh_host_dsa_key | set-acl C:\\ProgramData\\ssh\\administrators_authorized_keys"
        sshpass -p Netapp1! ssh -o StrictHostKeyChecking=no administrator@demo@jumphost.demo.netapp.com "get-acl C:\\ProgramData\\ssh\\ssh_host_dsa_key | set-acl C:\\ProgramData\\ssh\\administrators_authorized_keys"

        # add resource record for centos01 because ansible has hostname dependencies lmao
        sshpass -p Netapp1! ssh -o StrictHostKeyChecking=no administrator@demo@dc1.demo.netapp.com "Add-DnsServerResourceRecordA -Name "centos01" -IPv4Address "192.168.0.61" -ZoneName "demo.netapp.com" -AllowUpdateAny -TimeToLive "24:00:00""

        # setup Linux client
        sshpass -p Netapp1! ssh StrictHostKeyChecking=no root@centos01.demo.netapp.com mkdir -p ~/.ssh
        sshpass -p Netapp1! scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa.pub root@centos01.demo.netapp.com:~/.ssh/authorized_keys

        # add all your ssh dudes to the ansible hosts file
        echo "DC1.demo.netapp.com ansible_connection=ssh ansible_user=administrator@demo ansible_shell_type=powershell" >> /etc/ansible/hosts
        echo "jumphost.demo.netapp.com ansible_connection=ssh ansible_user=administrator@demo ansible_shell_type=powershell" >> /etc/ansible/hosts
        echo "centos01.demo.netapp.com ansible_connection=ssh anisble_user=root" >> /etc/ansible/hosts
        echo "awx.demo.netapp.com ansible_connection=ssh ansible_user=root" >> /etc/ansible/hosts
fi

# use curl instead
curl -L -o $playbook.yml https://raw.githubusercontent.com/HunkinsgAtNetapp/CORE_TAB/refs/heads/main/TAB/Playbooks/$playbook.yml

# play the playbook 
ansible-playbook $playbook.yml
