# Edge Functions

`image-transform` validates requests related to image processing. Configure Edge Function secrets through the Supabase dashboard; never commit service keys. Storage enforces the 2 MB limit and allowed MIME types before an image reaches the function.

Deploy `create-student` before using the administrator student-registration form:

```bash
supabase functions deploy create-student --no-verify-jwt
```

It creates the mobile login with initial password `admin123`; the student can change it in the Profile tab.
