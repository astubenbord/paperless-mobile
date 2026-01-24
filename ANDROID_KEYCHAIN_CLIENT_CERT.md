# Android client certificates via system KeyChain (no .pfx upload)

This change switches **Android** mutual‑TLS (client certificate) handling from
**uploading a PKCS#12 (`.pfx`) file** to **selecting a certificate that is
already installed** in Android's system credential store (**KeyChain**).

## Why

- On Android, Dart's `SecurityContext` / `HttpClient` cannot use private keys stored in Android KeyChain/Keystore.
- Selecting a KeyChain certificate avoids PKCS#12 parsing quirks and keeps the private key non‑exportable.

## Install your certificate into Android

Install the certificate into the system credential store:

1. Android **Settings** → **Security** → **Encryption & credentials**
2. **Install a certificate** → **VPN and apps**
3. Select your certificate/key file and complete the prompts

Where you find this menu varies by vendor (Pixel/Samsung), but the wording is usually similar.

## Use it in the app

On Android, the **Client certificate** section shows a picker:

1. Open **Client certificate**
2. Tap **Select**
3. Choose the certificate alias from the system picker
4. Continue login

To remove the selection, tap the **X** button.

## Implementation notes

- Flutter UI stores the selected alias in the existing `ClientCertificate` model (`androidKeyAlias`).
- Network requests are executed via a platform channel on Android using OkHttp configured with the selected KeyChain alias.
- Non‑Android platforms keep the existing `.pfx` upload flow.

## Security note

The current code keeps the previous behavior of accepting any server certificate (trust‑all) for parity with existing app behavior.
If you want proper server verification, remove the trust‑all `X509TrustManager` and hostname verifier in `MainActivity.kt`.
