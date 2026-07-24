insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('profile-images','profile-images',false,2097152,array['image/jpeg','image/png','image/webp']),
('program-posters','program-posters',false,2097152,array['image/jpeg','image/png','image/webp']),
('announcement-images','announcement-images',false,2097152,array['image/jpeg','image/png','image/webp']),
('documents','documents',false,2097152,array['application/pdf']) on conflict (id) do nothing;
create policy "staff upload files" on storage.objects for insert to authenticated with check (bucket_id in ('profile-images','program-posters','announcement-images','documents') and public.is_staff());
create policy "staff manage files" on storage.objects for all to authenticated using (bucket_id in ('profile-images','program-posters','announcement-images','documents') and public.is_staff());
create policy "authenticated read files" on storage.objects for select to authenticated using (bucket_id in ('profile-images','program-posters','announcement-images','documents'));
