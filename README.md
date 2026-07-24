# RRAcademy

RRAcademy is a Supabase-backed student management system with a Next.js admin portal and Expo student application.

## Requirements

- Node.js 20+
- npm 10+
- Supabase CLI (for local database development)
- An Expo account for EAS builds

## Quick start

1. Create a Supabase project and enable Email authentication.
2. In the Supabase SQL editor run `supabase/schema.sql`, then `supabase/storage.sql`, then `supabase/seed.sql`.
3. Copy `admin-portal/.env.example` to `admin-portal/.env.local` and set the project URL and anon key. Do the equivalent for `student-app/.env`.
4. Run `npm install` in `admin-portal`, then `npm run dev`.
5. Run `npm install` in `student-app`, then `npx expo start`.

## Storage

The project creates private buckets for profile images, program posters, announcement images, and documents. Never put a service-role key into either client application.

## Deployment

- **Admin:** import `admin-portal` into Vercel and configure the two `NEXT_PUBLIC_SUPABASE_*` variables.
- **Mobile:** configure the same `EXPO_PUBLIC_SUPABASE_*` variables, then run `eas build --platform android --profile preview` for APK or `--profile production` for AAB.

## Layout

- `admin-portal/` — role-aware web administration
- `student-app/` — student self-service mobile app
- `supabase/` — schema, policies, functions, and starter data
- `assets/` — local source-asset locations; uploadable assets go to Supabase Storage

## Troubleshooting

- “Not authorised” normally means the authenticated user does not have a matching `profiles.role`.
- Missing rows usually means RLS is doing its job. Confirm `auth.uid()` matches the profile/student relationship.
- If Expo cannot read configuration, restart Metro after editing `.env`.
