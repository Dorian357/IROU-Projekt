#cloud-config
# =============================================================================
# IRUO Projekt — Dorian
# Opis: Automatska inicijalizacija OpenStack VM-a pri prvom pokretanju
# Tip instance: ${tip_instance}
# =============================================================================

package_update: true
package_upgrade: false

packages:
  - epel-release
  - vim
  - curl
  - wget
  - git
  - htop
  - net-tools
  - bash-completion
%{ if tip_instance == "moodle" ~}
  - httpd
  - php
  - php-mysqlnd
  - php-gd
  - php-xml
  - php-mbstring
  - php-intl
  - php-zip
  - php-soap
  - mariadb
  - python3-swiftclient
%{ endif ~}

runcmd:
  # Formatiranje i montiranje data volumena (Cinder)
  - |
    if lsblk | grep -q vdb; then
      mkfs.xfs /dev/vdb
      mkdir -p /mnt/dorian-data-1612
      echo "/dev/vdb /mnt/dorian-data-1612 xfs defaults,nofail 0 2" >> /etc/fstab
      mount -a
    fi

%{ if tip_instance == "moodle" ~}
  # Pokretanje Apache web servera za Moodle
  - systemctl enable httpd
  - systemctl start httpd
  - firewall-cmd --permanent --add-service=http
  - firewall-cmd --permanent --add-service=https
  - firewall-cmd --reload

  # Kreiranje direktorija za Moodle i pohranu
  - mkdir -p /var/www/html/moodle
  - mkdir -p /mnt/dorian-swift
  - mkdir -p /mnt/dorian-backup-1612
%{ endif ~}

%{ if tip_instance != "bastion" && lokalni_korisnik != "" ~}
  # Kreiranje lokalnog korisnika Dorian
  - useradd -m -s /bin/bash ${lokalni_korisnik}
  - usermod -aG wheel ${lokalni_korisnik}
  - echo "${lokalni_korisnik} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${lokalni_korisnik}
%{ endif ~}

final_message: "IRUO Projekt Dorian — OpenStack VM tip ${tip_instance} uspjesno inicijaliziran nakon $UPTIME sekundi."
