terraform {

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.32.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
    doppler = {
        source = "DopplerHQ/doppler"
    }
  }
}

data "doppler_secrets" "env" {
  provider = doppler
}

locals {
  doppler-env = {
    map = data.doppler_secrets.env.map
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name = local.doppler-env.map.CF_DOMAIN
  }
}

resource "cloudflare_zone_settings_override" "cloudflare_settings" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  settings {
    ssl                      = "strict"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    universal_ssl            = "on"
    browser_check            = "on"
    challenge_ttl            = 1800
    privacy_pass             = "on"
    security_level           = "high"
    brotli                   = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    rocket_loader       = "on"
    always_online       = "on"
    development_mode    = "off"
    http3               = "on"
    zero_rtt            = "on"
    ipv6                = "on"
    websockets          = "on"
    opportunistic_onion = "on"
    pseudo_ipv4         = "add_header"
    ip_geolocation      = "on"
    email_obfuscation   = "on"
    server_side_exclude = "on"
    hotlink_protection  = "off"
    security_header {
      enabled = true
    }
  }
}

data "http" "ipv4" {
  url = "https://ipv4.icanhazip.com"
}

resource "cloudflare_record" "ipv4" {
  name    = "ipv4"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "root" {
  name    = local.doppler-env.map.CF_DOMAIN
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ingress.${local.doppler-env.map.CF_DOMAIN}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}
