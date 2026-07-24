# Operations

Create the first user in Supabase Auth, then promote the associated profile:

```sql
update public.profiles set role = 'super_admin' where email = 'owner@example.com';
```

The profile row is generated automatically when a user signs up. Create student users through the Supabase Auth dashboard or an administrative server-side workflow, then set `students.user_id` to their Auth UUID. Do not use a service-role key in browser or mobile code.
