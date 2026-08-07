# Possible issue with simultaneous apex and wildcard certificate requests

Hello,

First of all, thanks for maintaining this project.

While testing cert-manager with the TransIP webhook, I noticed behaviour that may indicate a problem when requesting certificates containing both an apex domain and a wildcard domain in the same `Certificate` resource.

## Environment

- cert-manager: quay.io/jetstack/cert-manager-controller:v1.20.2
- cert-manager-webhook-transip: demeesterdev/cert-manager-webhook-transip:0.1.4
- DNS provider: TransIP
- Kubernetes: v1.35.4+k3s1

## What works

Requesting a certificate for a single hostname works correctly:

```yaml
dnsNames:
  - pkntest.prjv.nl
```

Requesting a wildcard certificate also works correctly:

```yaml
dnsNames:
  - "*.prjv.nl"
```

Both complete successfully and the certificate is issued.

## Problematic case

A certificate containing both the apex domain and the wildcard domain appears to fail or behave inconsistently:

```yaml
dnsNames:
  - prjv.nl
  - "*.prjv.nl"
```

## Observations

- Individual certificates consistently succeed.
- DNS01 validation works correctly.
- TXT records are created and cleaned up correctly.
- The issue only seems to occur when both names are requested together in the same `Certificate` resource.
- Creating two separate `Certificate` resources, one for `prjv.nl` and one for `*.prjv.nl`, works reliably as a workaround.
- This makes me suspect there may be an issue related to handling multiple ACME challenges for the same DNS zone, possibly during challenge creation or cleanup.

## Question

Is this a known limitation or known issue?

If useful, I can provide additional details, such as:

- cert-manager logs
- webhook logs
- `Challenge` resources
- `Order` resources
- `CertificateRequest` resources
- the minimal `Certificate` manifests used for testing

Thanks.
