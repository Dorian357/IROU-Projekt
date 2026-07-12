# IROU-Projekt
Multi-Cloud Moodle projektna infrastruktura za firmu TechSprint 
# TechSprint — Multi-Cloud Moodle Infrastruktura
### IRUO Projekt — Dorian | 2025./2026.

Automatizirana multi-cloud infrastruktura za IT agenciju TechSprint.
Svaki programer dobiva izoliranu, neovisnu testnu okolinu za Moodle
aplikaciju — na Microsoft Azure i OpenStack platformama —
jednom naredbom iz CSV datoteke.

---

## Dijagrami arhitekture

### Azure arhitektura
<img width="2720" height="3280" alt="azure_arhitektura_dorian" src="https://github.com/user-attachments/assets/d37c4f2e-8453-4055-8997-2d75e3156a48" />

### OpenStack arhitektura
<img width="2720" height="3280" alt="openstack_arhitektura_dorian" src="https://github.com/user-attachments/assets/33c4b818-20aa-41db-a419-5ae149863630" />

### Azure RBAC model
<img width="2720" height="2964" alt="azure_rbac_dorian_v2" src="https://github.com/user-attachments/assets/afbcb2cc-3fe0-44ad-b021-ecf89df0c2ee" />

### OpenStack Keystone IAM
<img width="2720" height="2991" alt="openstack_iam_dorian" src="https://github.com/user-attachments/assets/6cc26c86-0cfe-42d4-9437-d98fd7f2cf23" />

---

## Struktura projekta
IROU-Projekt/
├── csv/
│   └── users.csv               # Korisnici (ime;prezime;rola)
├── azure/
│   ├── deploy.sh               # Deployment skripta (čita CSV)
│   ├── main.tf                 # Root Terraform modul
│   ├── variables.tf            # Varijable
│   ├── outputs.tf              # Izlazne vrijednosti
│   └── modules/
│       ├── network/            # VNet, NSG, NAT Gateway, Peering
│       ├── vm/                 # Virtual Machines, cloud-init
│       ├── loadbalancer/       # Azure Standard LB
│       ├── storage/            # Blob Storage + Azure Files
│       └── iam/                # Custom RBAC rola, dodjele
├── openstack/
│   ├── deploy.sh               # Deployment skripta (čita CSV)
│   ├── main.tf                 # Root Terraform modul
│   ├── variables.tf            # Varijable
│   ├── outputs.tf              # Izlazne vrijednosti
│   └── modules/
│       ├── network/            # Neutron mreže, Security grupe
│       ├── vm/                 # Nova instance, Cinder volumen
│       ├── loadbalancer/       # Octavia LBaaS v2
│       ├── storage/            # Swift + Cinder backup
│       └── iam/                # Keystone projekti, korisnici, role
└── docs/                       # Dijagrami arhitekture

---

## Format CSV datoteke
ime;prezime;rola
ana;anic;devops_lead
luka;lukic;developer
maja;majic;developer

Podržane uloge: `devops_lead`, `developer`

---

## Deployment

### Preduvjeti

- Terraform >= 1.6
- Azure: Azure CLI (`az login`)
- OpenStack: RC file (`source keystonerc_admin`)
- SSH ključ na `~/.ssh/id_rsa.pub`

### Azure

```bash
cd azure
chmod +x deploy.sh
./deploy.sh ../csv/users.csv
```

### OpenStack

```bash
source ~/keystonerc_admin
cd openstack
chmod +x deploy.sh
./deploy.sh ../csv/users.csv
```

### SSH pristup

```bash
# Bastion (Jump Host)
ssh azureuser@<bastion_public_ip>

# Voditelj (kroz Bastion)
ssh -J azureuser@<bastion_ip> azureuser@<voditelj_private_ip>

# Developer VM (kroz Bastion)
ssh -J azureuser@<bastion_ip> azureuser@<dev_vm_private_ip>
```

---

## Komponente infrastrukture

### Azure

| Komponenta | Servis | Specifikacija |
|---|---|---|
| Bastion VM | Azure VM | Standard_B1s, javna IP |
| Voditelj VM | Azure VM | Standard_D2s_v3, 2 vCPU/8GB |
| Moodle VM (×2/dev) | Azure VM | Standard_D2s_v3, 2 vCPU/8GB |
| Objektna pohrana | Azure Blob | Standard LRS, blobfuse2 |
| Datotečna pohrana | Azure Files | Standard LRS, SMB |
| Load Balancer | Azure Standard LB | Interni, Round Robin |
| Firewall | NSG | Whitelist pravila |
| IAM | Azure RBAC | Custom rola + Managed Identity |

### OpenStack

| Azure | OpenStack ekvivalent |
|---|---|
| Virtual Machine | Nova instance |
| VNet | Neutron Network |
| NSG | Security Group |
| Azure LB | Octavia LBaaS v2 |
| Blob Storage | Swift Object Storage |
| Azure Files | Cinder Volume |
| Azure RBAC | Keystone Users + Projects |
| NAT Gateway | Neutron Router |

---

## Mrežna izolacija

- Svaki developer ima zasebni VNet/Neutron mrežu
- Nema komunikacije između developer mreža
- Jedini javni pristup: Bastion VM
- NSG/Security grupe blokiraju sve osim SSH s bastiona

## IP shema (bazirana na datumu rodjendana 16.12.)

| Zona | Azure CIDR | OpenStack CIDR |
|---|---|---|
| Management | 10.16.0.0/16 | 172.16.0.0/24 |
| Bastion subnet | 10.16.1.0/24 | 172.16.0.0/24 |
| Voditelj subnet | 10.16.2.0/24 | 172.16.0.0/24 |
| Developer 1 | 10.12.1.0/24 | 172.12.1.0/24 |
| Developer 2 | 10.12.2.0/24 | 172.12.2.0/24 |

---

## IAM model

### Azure RBAC

| Identitet | Scope | Rola |
|---|---|---|
| Developer VM (MSI) | vlastita RG | Custom VM Operator 1612 |
| Voditelj VM (MSI) | sve developer RG | VM Contributor + Reader |

### OpenStack Keystone

| Korisnik | Scope | Rola |
|---|---|---|
| Developer | vlastiti projekt | member |
| Voditelj | svi projekti | admin |

---

## Procjena troškova (Azure)

Konfiguracija: 1 voditelj + 2 developera, West Europe, Pay-as-you-go

| Resurs | Kol. | USD/mj. |
|---|---|---|
| Bastion VM (Standard_B1s) | 1 | $7.59 |
| Voditelj VM (Standard_D2s_v3) | 1 | $70.08 |
| Moodle VM (Standard_D2s_v3) | 4 | $280.32 |
| Premium SSD diskovi | 11 | $106.87 |
| NAT Gateway | 3 | $98.55 |
| Azure Standard LB | 2 | $36.50 |
| Blob + Files Storage | 4 | $8.00 |
| Javna IP (Bastion) | 1 | $3.65 |
| **UKUPNO** | | **~$611.56** |

OpenStack: samo troškovi hardvera (bez licencnih naknada)

---

## Konvencija imenovanja

Format: `techsprint-<tip>-<komponenta>-<korisnik>`

Primjeri:
- `techsprint-rg-upravljanje` — management resource grupa
- `techsprint-rg-luka.lukic` — developer resource grupa
- `techsprint-vm-bastion-dorian` — Bastion VM
- `techsprint-vm-voditelj-ana.anic` — Voditeljev VM
- `techsprint-vm-luka.lukic-app-1-dorian` — Moodle VM 1

---

## Tagovi

Svi resursi imaju tagove:
project     = "techsprint"
environment = "testing"
managed_by  = "terraform"
autor       = "dorian"

---

## Brisanje infrastrukture

```bash
cd azure
terraform destroy

cd openstack
terraform destroy
```

---

*IRUO Projekt — Dorian | 2025./2026.*
'@ | Set-Content README.md -Encoding UTF8
