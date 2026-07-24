-- Deliberately contains no student records. Production data should never be seeded into the client application.
insert into public.programs(name,description) values ('Foundation Program','Core academic and skills development') on conflict (name) do nothing;
