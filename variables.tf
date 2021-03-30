# ----------------- Authentication's variables ---------------- #
variable "tenant_id" {
  description = "The Tenant ID required for your organization"
  type       = string
  default    = "e238a5a8-4a4d-49be-a214-d616362601d1"
}

variable "subscription_id" {
  description = "Specify the subscription for the project with ID"
  type       = string
  default    = "b0cf6192-6438-4006-8d3b-9f97f91843a5"
}

variable "user_id" {
  description = "Specify the User/Service Principle linked to the subscription"
  type       = string
  default    = "8e9dbee5-0265-42b0-b689-1db46ad8777f"
}

variable "user_secret" {
  description = "User/Service Principle password"
  type       = string
  default    = "sXcrAJLkBYhwtgJ~vqUtV~lqXYSMHWG~a9"
}

variable "rg_region" {
  description = "Specify where the related RG located"
  type       = string
  default    = "North Central US"
}
# ------------ API Management Service's variables ------------- #
variable "apimServiceName" {
  description = "Specify the name of the API Management service"
  type       = string
  default    = "APIM-POC-ps2tf"
}

variable "apimOrganization" {
  description = "Specify the name of Organization"
  type       = string
  default    = "PDL-APIM"
}

variable "apimAdminEmail" {
  description = "Specify the administrator's email address"
  type       = string
  default    = "srikanth.randhi@labs.com"
}

variable "gatewayHostname" {
  description = "API gateway host"
  type        = string
  default     = "api7.outstacart.com"
}

variable "portalHostname" {
  description = "API developer portal host"
  type        = string
  default     = "portal7.outstacart.com"
}

variable "gatewayCertCerPath" {
  description = "Full path to api.yourdomain.co.uk .cer file"
  type        = string
  default     = "C:\\Users\\opsadmin\\api7.outstacart.cer"
}

variable "gatewayCertPfxPath" {
  description = "Full path to api.yourdomain.co.uk .pfx file"
  type        = string
  default     = "C:\\Users\\opsadmin\\api7.outstacart.pfx"
}

variable "portalCertPfxPath" {
  description = "Full path to portal.yourdomain.co.uk .pfx file"
  type        = string
  default     = "C:\\Users\\opsadmin\\api7.outstacart.pfx"
}

variable "gatewayCertPfxPassword" {
  description = "Password for api.yourdomain.co.uk pfx certificate"
  type        = string
  default     = "welcome123"
}

variable "portalCertPfxPassword" {
  description = "Password for portal.yourdomain.co.uk pfx certificate"
  type        = string
  default     = "welcome123"
}

# ------------- Deploy Application Gateway ------------- #
variable "appgwName" {
  description = "Name for deployment of the App Gateway"
  type        = string
  default     = "apim-app-gw-pdl"
}