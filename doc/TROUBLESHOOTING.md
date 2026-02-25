# Troubleshooting

## SAML IdP metadata SSL CRL failures

If app boot fails with `certificate verify failed (unable to get certificate CRL)` while fetching SAML IdP metadata:

- Add the IdP CRL(s) to the OpenSSL trust store at `/opt/homebrew/etc/openssl@3/certs` and run `c_rehash`.
- Or set `COB_SAML_IDP_METADATA_FILE` to a local IdP metadata XML for development bootstrapping.
