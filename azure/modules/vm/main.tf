# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure VM
# Opis: Kreira virtualnu masinu s Rocky Linuxom, NIC-om, diskovima
# =============================================================================

# Javna IP adresa — iskljucivo za bastion VM
resource "azurerm_public_ip" "dorian_pip" {
  count               = var.javna_ip ? 1 : 0
  name                = "${var.ime_vm}-pip"
  location            = var.regija
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.oznake
}

# Mrezno sucelje (NIC)
resource "azurerm_network_interface" "dorian_nic" {
  name                = "${var.ime_vm}-nic"
  location            = var.regija
  resource_group_name = var.resource_group_name
  tags                = var.oznake

  ip_configuration {
    name                          = "dorian-ip-konfiguracija"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.javna_ip ? azurerm_public_ip.dorian_pip[0].id : null
  }
}

# Podatkovni disk (ne koristi bastion)
resource "azurerm_managed_disk" "dorian_data_disk" {
  count                = var.data_disk ? 1 : 0
  name                 = "${var.ime_vm}-data-disk-1612"
  location             = var.regija
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_gb
  tags                 = var.oznake
}

# Virtualna masina s Rocky Linux operacijskim sustavom
resource "azurerm_linux_virtual_machine" "dorian_vm" {
  name                = var.ime_vm
  location            = var.regija
  resource_group_name = var.resource_group_name
  size                = var.velicina_vm
  admin_username      = var.admin_korisnik
  tags                = var.oznake

  # System-assigned Managed Identity
  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [azurerm_network_interface.dorian_nic.id]

  admin_ssh_key {
    username   = var.admin_korisnik
    public_key = var.ssh_kljuc
  }

  os_disk {
    name                 = "${var.ime_vm}-os-disk-1612"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_gb
  }

  # Rocky Linux 9 cloud image
  source_image_reference {
    publisher = "erockyenterprise"
    offer     = "rockylinux-x86_64"
    sku       = "free"
    version   = "latest"
  }

  plan {
    name      = "free"
    publisher = "erockyenterprise"
    product   = "rockylinux-x86_64"
  }

  # cloud-init za automatsku inicijalizaciju VM-a
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tpl", {
    tip_instance     = var.tip_instance
    lokalni_korisnik = var.lokalni_korisnik
  }))

  disable_password_authentication = true
}

# Spajanje podatkovnog diska na VM
resource "azurerm_virtual_machine_data_disk_attachment" "dorian_disk_attach" {
  count              = var.data_disk ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.dorian_data_disk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.dorian_vm.id
  lun                = 0
  caching            = "ReadWrite"
}
