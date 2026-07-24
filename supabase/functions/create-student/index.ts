// Deploy: supabase functions deploy create-student --no-verify-jwt
// Configure SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY as Edge secrets.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
type Input = { student_number: string; full_name: string; email: string; phone?: string; guardian_name?: string };
Deno.serve(async (request) => {
  const authHeader = request.headers.get('Authorization') ?? '';
  const caller = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await caller.auth.getUser(); if (!user) return new Response('Unauthorised', { status: 401 });
  const service = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: profile } = await service.from('profiles').select('role').eq('id', user.id).single(); if (!profile || !['admin','super_admin'].includes(profile.role)) return new Response('Forbidden', { status: 403 });
  const input = await request.json() as Input;
  const { data: created, error: accountError } = await service.auth.admin.createUser({ email: input.email.toLowerCase(), password: 'admin123', email_confirm: true, user_metadata: { full_name: input.full_name } });
  if (accountError || !created.user) return Response.json({ error: accountError?.message ?? 'Account creation failed.' }, { status: 400 });
  const { data: student, error } = await service.from('students').insert({ ...input, email: input.email.toLowerCase(), user_id: created.user.id }).select().single();
  if (error) { await service.auth.admin.deleteUser(created.user.id); return Response.json({ error: error.message }, { status: 400 }); }
  return Response.json({ student, initial_password: 'admin123' }, { status: 201 });
});
