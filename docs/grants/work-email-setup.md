# Work email setup — richard@stonkrobotics.xyz

**Status: forwarding configured 2026-09-21. Verified MX at Porkbun; propagation pending.**

## What is set up

| Item | Value |
|---|---|
| Forward address | `richard@stonkrobotics.xyz` (and `hello@stonkrobotics.xyz` if added) |
| Delivers to | `ritsuyan4763@gmail.com` |
| Registrar | Porkbun (`stonkrobotics.xyz` registered there; DNS powered by Cloudflare) |
| MX records | `fwd1.porkbun.com` prio 10, `fwd2.porkbun.com` prio 20 |
| SPF | `v=spf1 include:_spf.porkbun.com ~all` |
| DKIM | `default._domainkey` TXT present |
| DMARC | `v=DMARC1; p=quarantine` with rua/ruf reporting |

Configured in Porkbun → **Email Hosting and Forwarding** → **Email Forwarding**.
Free tier: up to 20 forwards per domain.

## Verify it works

```bash
# MX should resolve from public resolvers (allow 5-10 min after saving)
dig @8.8.8.8 stonkrobotics.xyz MX +short
# expected: 10 fwd1.porkbun.com.  /  20 fwd2.porkbun.com.
```

Then send a test from any external mailbox to `richard@stonkrobotics.xyz` and
confirm it arrives in Gmail. **Do this before submitting any application that
lists the address**, so a bounce does not surface during reviewer diligence.

## Sending as the work address (Gmail "Send mail as")

Receiving works via DNS forwarding. To *send* from `richard@stonkrobotics.xyz`
in Gmail you need SMTP credentials — Gmail's POP3 fetching is deprecated as of
January 2026, but SMTP sending still works.

Two options:

**A. Send via Gmail SMTP with the Porkbun mailbox** (requires a paid Porkbun
email hosting account, $3/mo, because SMTP sending needs a real mailbox —
forwarding alone has no outgoing server).

**B. Send via Gmail on-behalf-of with an alias** (free, no extra mailbox):
1. Gmail → Settings → Accounts and Import → "Send mail as" → Add another address
2. Enter `richard@stonkrobotics.xyz`
3. Choose "Send through Gmail" is NOT possible for a custom domain you do not
   control the mailbox for — so this option only works with a real mailbox.

**Practical recommendation for applications:** receiving at
`richard@stonkrobotics.xyz` is the part that matters — the address on an
application is a *contact* address, and a reply must reach you. That works
today. If you later need to initiate outbound email from the domain, buy the
$3/mo Porkbun mailbox (option A) rather than fighting Gmail aliases.

## Where the address is used

Replaced across all application materials (`ritsuyan4763@gmail.com` →
`richard@stonkrobotics.xyz`) in:
- `canonical-fact-sheet.md`
- `circle-developer-grant-draft.md`
- `portal-submission.md`
- `arc-builders-fund-deck-outline.md`

**Note:** the Circle Grants Cohort 2 submission was already sent with the Gmail
address. If a reviewer replies there it still reaches the same inbox, so no
action is needed — but mention the work address in any follow-up.
