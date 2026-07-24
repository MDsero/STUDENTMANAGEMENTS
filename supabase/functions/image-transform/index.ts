// Deploy with: supabase functions deploy image-transform
// This function validates an image upload request. Actual WebP resizing is normally
// performed by an image worker/CDN; keep the service-role key only in Edge secrets.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const authorization = request.headers.get('Authorization') ?? '';
  const client = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: authorization } } });
  const { data: { user } } = await client.auth.getUser();
  if (!user) return new Response('Unauthorised', { status: 401 });
  const payload = await request.json() as { bucket?: string; path?: string; contentType?: string; size?: number };
  if (!payload.bucket || !payload.path || !payload.contentType?.startsWith('image/') || !payload.size || payload.size > 2_097_152) {
    return Response.json({ error: 'Invalid image request' }, { status: 400 });
  }
  // The source file is already constrained by Storage policy. Return a stable path
  // that clients can cache; configure an image transformation provider if desired.
  return Response.json({ path: payload.path, bucket: payload.bucket, accepted: true });
});
