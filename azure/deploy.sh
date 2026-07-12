#!/usr/bin/env bash
# =============================================================================
# IRUO Projekt — Dorian
# Platforma: Microsoft Azure
# Opis: Deployment skripta koja cita CSV i automatski kreira infrastrukturu
# Koristenje: ./deploy.sh <putanja_do_csv>
# =============================================================================

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "GRESKA: Nedostaje putanja do CSV datoteke."
  echo "Koristenje: $0 <putanja_do_csv>"
  exit 1
fi

CSV_FILE="$1"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "GRESKA: CSV datoteka ne postoji."
  exit 1
fi

echo "=================================================="
echo " IRUO Projekt Dorian"
echo " TechSprint Azure Deployment"
echo "=================================================="
echo ""

echo "[1/6] Provjera preduvjeta..."

for cmd in terraform az; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "GRESKA: nije instaliran."
    exit 1
  fi
done

if ! az account show &>/dev/null; then
  echo "Niste prijavljeni u Azure. Pokretanje az login..."
  az login
fi

echo "  OK Terraform instaliran"
echo "  OK Azure CLI instaliran"
echo "  OK Azure racun: $(az account show --query name -o tsv)"
echo ""

echo "[2/6] Provjera SSH kljuca..."
SSH_KEY_PATH="${TF_VAR_ssh_public_key_path:-$HOME/.ssh/id_rsa.pub}"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  ssh-keygen -t rsa -b 4096 -f "${SSH_KEY_PATH%.pub}" -N "" -C "dorian-techsprint-1612"
  echo "  OK SSH kljuc generiran"
else
  echo "  OK SSH kljuc pronadjen: $SSH_KEY_PATH"
fi

SSH_PUBLIC_KEY=$(cat "$SSH_KEY_PATH")
echo ""
echo "[3/6] Parsiranje CSV datoteke: $CSV_FILE"

DEV_TIM=()
VODITELJ=""

while IFS=';' read -r ime prezime rola; do
  [[ "$ime" == "ime" ]] && continue
  [[ -z "$ime" ]] && continue

  KORISNIK="${ime,,}.${prezime,,}"

  if [[ "$rola" == "devops_lead" ]]; then
    VODITELJ="$KORISNIK"
    echo "  OK Voditelj tima: $KORISNIK"
  elif [[ "$rola" == "developer" ]]; then
    DEV_TIM+=("$KORISNIK")
    echo "  OK Developer: $KORISNIK"
  else
    echo "  UPOZORENJE: Nepoznata rola, preskacemo."
  fi
done < "$CSV_FILE"

if [[ -z "$VODITELJ" ]]; then
  echo "GRESKA: CSV ne sadrzi korisnika s rolom devops_lead."
  exit 1
fi

if [[ ${#DEV_TIM[@]} -eq 0 ]]; then
  echo "GRESKA: CSV ne sadrzi niti jednog developera."
  exit 1
fi

echo ""
echo "  Sazetak:"
echo "    Voditelj:   $VODITELJ"
echo "    Developeri: ${DEV_TIM[*]}"
echo "    Ukupno VM-ova: $((${#DEV_TIM[@]} * 2 + 2))"
echo ""

echo "[4/6] Generiranje terraform.auto.tfvars..."

TFVARS_FILE="$(dirname "$0")/terraform.auto.tfvars"

DEV_LISTA=""
for dev in "${DEV_TIM[@]}"; do
  DEV_LISTA+="    "$dev","$'\n'
done

cat > "$TFVARS_FILE" <<TFEOF
# AUTO-GENERIRANO od deploy.sh
# IRUO Projekt Dorian 16.12.

azure_region = "westeurope"
team_lead    = "$VODITELJ"
ssh_key      = "$SSH_PUBLIC_KEY"

dev_team = [
$DEV_LISTA]

resource_tags = {
  project     = "techsprint"
  environment = "testing"
  managed_by  = "terraform"
  autor       = "dorian"
  datum       = "16-12"
}
TFEOF

echo "  OK terraform.auto.tfvars generiran"
echo ""

echo "[5/6] Pokretanje Terraform deploymenta..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "--- terraform init ---"
terraform init -upgrade

echo "--- terraform validate ---"
terraform validate

echo "--- terraform plan ---"
terraform plan -out=tfplan-dorian-1612

echo "--- terraform apply ---"
terraform apply tfplan-dorian-1612

echo ""
echo "[6/6] Deployment zavrsen!"
terraform output

echo ""
echo "=================================================="
echo " IRUO Projekt Dorian 16.12."
echo " TechSprint Azure infrastruktura uspjesno kreirana!"
echo "=================================================="
echo ""
echo "SSH pristup:"
echo "  Bastion:  ssh azureuser@$(terraform output -raw bastion_public_ip)"
echo "  Voditelj: ssh -J azureuser@$(terraform output -raw bastion_public_ip) azureuser@$(terraform output -raw team_lead_private_ip)"
echo ""
echo "Za brisanje: terraform destroy"
