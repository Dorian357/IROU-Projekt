#cloud-config
# =============================================================================
# IRUO Projekt — Dorian
# Opis: Automatska inicijalizacija VM-a pri prvom pokretanju
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
  - cifs-utils
  - fuse
%{ endif ~}

runcmd:
  # Formatiranje i montiranje podatkovnog diska
  - |
    if lsblk | grep -q sdc; then
      mkfs.xfs /dev/sdc
      mkdir -p /mnt/dorian-data
      echo "/dev/sdc /mnt/dorian-data xfs defaults,nofail 0 2" >> /etc/fstab
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
  - mkdir -p /mnt/dorian-blob
  - mkdir -p /mnt/dorian-backup

  # Instalacija blobfuse2 za Azure Blob Storage
  - rpm --import https://packages.microsoft.com/keys/microsoft.asc
  - dnf install -y https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm || true
  - dnf install -y blobfuse2 || true
%{ endif ~}

%{ if tip_instance != "bastion" && lokalni_korisnik != "" ~}
  # Kreiranje lokalnog korisnika
  - useradd -m -s /bin/bash ${lokalni_korisnik}
  - usermod -aG wheel ${lokalni_korisnik}
  - echo "${lokalni_korisnik} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${lokalni_korisnik}
%{ endif ~}

final_message: "IRUO Projekt Dorian — VM tip ${tip_instance} uspjesno inicijaliziran nakon $UPTIME sekundi."
