#!/usr/bin/env bash
# =============================================================================
# IRUO Projekt — Dorian
# Platforma: OpenStack
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
echo " TechSprint OpenStack Deployment"
echo "=================================================="
echo ""

echo "[1/6] Provjera preduvjeta..."

for cmd in terraform openstack; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "GRESKA: $cmd nije instaliran."
    exit 1
  fi
done

if [[ -z "${OS_AUTH_URL:-}" ]]; then
  echo ""
  echo "OpenStack RC varijable nisu postavljene."
  echo "Molimo pokrenite: source keystonerc_admin"
  exit 1
fi

echo "  OK Terraform instaliran"
echo "  OK OpenStack CLI instaliran"
echo "  OK Auth URL: $OS_AUTH_URL"
echo "  OK Korisnik: ${OS_USERNAME:-nije postavljen}"
echo ""

echo "[2/6] Provjera SSH kljuca..."
SSH_KEY_PATH="${TF_VAR_ssh_public_key_path:-$HOME/.ssh/id_rsa.pub}"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  ssh-keygen -t rsa -b 4096 -f "${SSH_KEY_PATH%.pub}" -N "" -C "dorian-techsprint-openstack-1612"
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
# IRUO Projekt Dorian

os_auth_url   = "$OS_AUTH_URL"
os_regija     = "${OS_REGION_NAME:-RegionOne}"
voditelj_tima = "$VODITELJ"
ssh_kljuc     = "$SSH_PUBLIC_KEY"

dev_tim = [
$DEV_LISTA]

resource_tags = {
  project     = "techsprint"
  environment = "testing"
  managed_by  = "terraform"
  autor       = "dorian"
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
terraform plan -out=tfplan-dorian-openstack-1612

echo "--- terraform apply ---"
terraform apply tfplan-dorian-openstack-1612

echo ""
echo "[6/6] Deployment zavrsen!"
terraform output

echo ""
echo "=================================================="
echo " IRUO Projekt Dorian"
echo " TechSprint OpenStack infrastruktura uspjesno kreirana!"
echo "=================================================="
echo ""
echo "SSH pristup:"
echo "  Bastion:  ssh rocky@$(terraform output -raw bastion_floating_ip)"
echo "  Voditelj: ssh -J rocky@$(terraform output -raw bastion_floating_ip) rocky@$(terraform output -raw voditelj_privatna_ip)"
echo ""
echo "Za brisanje: terraform destroy"
