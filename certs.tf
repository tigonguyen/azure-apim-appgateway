provider "local" {
  
}

data "local_file" "gatewayCertCer" {
  filename = var.gatewayCertCerPath
}

data "local_file" "gatewayCertPfx" {
  filename = var.gatewayCertPfxPath
}

data "local_file" "portalCertPfx" {
  filename = var.portalCertPfxPath
}