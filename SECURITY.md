# Security Policy

## API Key Protection
EchoScript handles sensitive Gemini API keys. We follow enterprise-grade security standards for key management:

1.  **Encryption at Rest:** API keys are never stored in plain text or local storage. We use `flutter_secure_storage` which utilizes Keychain (iOS) and Keystore (Android) for hardware-level encryption.
2.  **Zero-Commit Policy:** Never commit `.env` files, API keys, or secrets to version control. Our `.gitignore` is pre-configured to block common secret files.
3.  **Transmission Security:** All API calls to Gemini and the File Upload API are performed over HTTPS.

## Reporting a Vulnerability
If you discover a security vulnerability within EchoScript, please do not open a public issue. Instead:
1.  Email the maintainers directly (security@echoscript.ai).
2.  Provide a detailed description of the vulnerability and steps to reproduce.
3.  Allow the team 7 days to provide a fix before public disclosure.

## Local Development Security
*   Always use a dedicated development API key with restricted quotas for local testing.
*   Avoid using the production key in your local environment.
*   If your device is rooted or jailbroken, secure storage might be compromised.
