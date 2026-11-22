# Supabase, Firebase, Cloudinary, and payment integrations

## Subscription payment demo

Paid landlord plans use a simulated payment flow for the project demo. The app
records a simulated order in Supabase and activates the plan for 30 days; it
does not call a bank or SePay and does not collect money. Apply the latest SQL
migration and deploy the updated `subscription-api` function for this flow.
The SePay webhook and its secret are not required for simulated payments.

## Data ownership

- Firebase Authentication remains the sign-in provider.
- Cloud Firestore remains the source of truth for user profiles, properties,
  rooms, leases, invoices, messages, and tenant/landlord records.
- Supabase Postgres stores subscription orders and payment settings. SePay
  transaction records and unmatched transfers remain available for the legacy
  webhook integration, but the current landlord plan flow uses simulated
  payments and does not send transactions to SePay.
- Cloudinary stores uploaded media. Supabase Edge Functions issue Cloudinary
  signatures and short-lived links. For Firestore authorization, the function
  forwards the signed-in user's Firebase ID token, so Firestore Security Rules
  continue to enforce the caller's access.

No Google service-account key is required. Firestore REST requests made with a
Firebase Authentication ID token are evaluated by Firestore Security Rules.

## Firebase sign-in providers

Firebase Authentication stays in charge of sign-in. Email/Password and Phone
are enabled in project `tropremium-d14ac`; the SMS region policy is limited to
Vietnam. Google Sign-In is enabled and Android OAuth clients are configured.

Sending real phone verification SMS requires linking a Cloud Billing account
and moving the Firebase project to the Blaze plan. Firebase bills phone auth
per SMS. Email/Password and Google sign-in do not require this upgrade. See
[Firebase Authentication limits](https://firebase.google.com/docs/auth/limits)
and [Firebase pricing](https://firebase.google.com/pricing) before enabling
real phone-SMS traffic.

## Supabase Edge Functions

- `cloudinary-upload-signature`: verifies the Firebase ID token and checks the
  caller's Firestore access before signing an upload.
- `cloudinary-private-download-url`: checks Firestore access before returning
  a five-minute Cloudinary download URL.
- `subscription-api`: verifies Firebase ID tokens and the user's Firestore
  profile, then handles simulated payments, landlord orders, admin review, and
  the one-time import of legacy Firestore subscription records.
- `sepay-webhook`: optional legacy integration that verifies SePay's
  `Authorization: Apikey ...` header and matches incoming transfers to
  Supabase subscription orders.

The Supabase gateway has JWT verification disabled for these functions because
the app authenticates with Firebase and SePay authenticates with its API Key.
Every function verifies its own credentials. Supabase's secret key is used
only inside Edge Functions and is never sent to Flutter.

## Secrets

These project secrets are used by the deployed functions:

- `FIREBASE_PROJECT_ID` = `tropremium-d14ac`
- `SEPAY_WEBHOOK_API_KEY` = required only when enabling the optional SePay webhook
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

Supabase supplies the Edge Function's own server key automatically. Do not add
it to the Flutter app. `GOOGLE_SERVICE_ACCOUNT_JSON` is not used by this design.

## Database and deployment

The SQL migration is in `backend/supabase/migrations`. From that directory, run:

```powershell
npx.cmd supabase db push --linked
npx.cmd supabase functions deploy --use-api
```

Apply the latest migration before deploying the updated `subscription-api`.
The first time an admin opens the subscription management page in the updated
app, it imports existing payment settings, orders, and unmatched transfers
from Firestore into Supabase in retryable batches. The original Firestore
documents are retained as a backup and made read-only; do not delete them
manually.

The linked Supabase project is `hihsjrdzbtfldlscigzi`. Its SePay webhook URL
remains:

```text
https://hihsjrdzbtfldlscigzi.supabase.co/functions/v1/sepay-webhook
```

The SePay webhook can remain unconfigured while the app uses simulated
subscription payments. If enabled separately, configure it for incoming
transactions, JSON payloads, and API Key authentication. Its API Key must
exactly match `SEPAY_WEBHOOK_API_KEY` in Supabase.

## Flutter configuration

The Supabase function URL and publishable key are compiled as client defaults.
For another environment, override them with:

```powershell
flutter run `
  --dart-define=TROPREMIUM_INTEGRATIONS_BACKEND_URL=https://YOUR_PROJECT_REF.supabase.co/functions/v1 `
  --dart-define=TROPREMIUM_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Use the same defines for release builds. Publishable keys are safe for client
apps; Cloudinary API secrets, SePay webhook keys, and Supabase secret keys are
not. Supabase injects the server secret key into Edge Functions, so no
service-role key needs to be added to the app or project secrets.
