# Overview

Moving parts to allow [Let's Encrypt](https://letsencrypt.org/)
[`certbot`](https://certbot.eff.org/) validate domains using DNS challenge where

* the DNS server is [djbdns](https://cr.yp.to/djbdns/tinydns.html)'s `tinydns`
* the DNS server is not co-located with the server running `certbot`

# Components

* [`certbot`](https://certbot.eff.org/) on the server request the certificate
* [`tinydns`](https://cr.yp.to/djbdns/tinydns.html) on the DNS server
* [`webhook`](https://github.com/adnanh/webhook) on the DNS server

# Installation

On the DNS server, `server/*` into `/var/service/tinydns/root`
On the DNS server, `webhook/*` into `/var/service/tinydns-webhook`
On the requesting client, `client/*` into `PATH` somewhere

# Flow

Here `C` indicates the server requesting the certificate using `certbot` and
`D` indicates the server running `tinydns`.

1. `certbot` invoked with DNS hooks (on `C`):

```
certbot certonly --preferred-challenges dns --manual \
  --manual-public-ip-logging-ok \
  --non-interactive \
  --manual-auth-hook certbot-auth-remote
  --manual-cleanup-hook certbot-auth-remote
```

3. `certbot-auth-remote` is called from `certbot` to create the validation
   record (both on `C`)

4. `certbot-auth-remote` (on `C`) `POST`s the domain, the validation record,
   and `add` to the webhook (on `D`) along with a signature

5. the webhook checks the signature and calls `certbot-webhook` (on `D`)

6. `certbot-webhook` calls `manage-certbot-records` (both on `D`)

7. `manage-certbot-records` adds the validation record to
   `auto/${DOMAIN}.certbot` and rebuild the `tinydns` data (on `D`)

8. Offstage, letsencrypt queries and confirms the validation record is in the
   DNS

9. `certbot-auth-remote` is called from `certbot` to remove the validation
   record (both on `C`)

10. `certbot-auth-remote` (on `C`) `POST`s the domain and `remove` to the
    webhook (on `D`) again, which calls `certbot-webhook`

11. `certbot-webhook` calls `manage-certbot-records` (both on `D`)

12. `manage-certbot-records` removes the validation records and rebuilds the
    `tinydns` data (on `D`)


# Notes

* `make-tinydns` is just `sudo` wrapper to run `make` in `djbdns/root`, where
  the `data` is a concatenation of the static `tinydns` data (here: `data.scm`)
  and any files created by `manage-certbot-records` (`auto/*`):

```
data.cdb: build-data
        tinydns-data

build-data: data.scm
        @mkdir -p /var/service/tinydns/auto
        @touch /var/service/tinydns/auto/0
        cat /var/service/tinydns/data.scm /var/service/tinydns/auto/* > data.new
```

* the separation of `certbot-webhook` and `manage-certbot-records` allows a
  user switch between the webhook and the DNS build operation (here: with
  `sudo`)

* multiple webhooks can be used for differently clients, but there's no
  checking which client is permitted to operate which domain

* none of this is considered super-done, just an itch for a scratch

# License

MIT. See LICENSE for text.

# Author

Jon Stuart, Zikomo Technology, 2023 
