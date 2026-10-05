-- Permite calificar (o cambiar la calificación de) un punto ya desbloqueado.
-- Supuestos (verificar contra el esquema real antes de ejecutar):
--   * visitas(usuario_id, punto_id, calificacion smallint null)
--   * puntos_de_interes.calificacion_promedio numeric
create or replace function public.calificar_punto(
  p_usuario uuid,
  p_punto bigint,
  p_calificacion int
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is distinct from p_usuario then
    raise exception 'No autorizado';
  end if;
  if p_calificacion < 1 or p_calificacion > 5 then
    raise exception 'La calificación debe estar entre 1 y 5';
  end if;

  update visitas
     set calificacion = p_calificacion
   where usuario_id = p_usuario and punto_id = p_punto;

  if not found then
    raise exception 'Debes desbloquear el punto antes de calificarlo';
  end if;

  update puntos_de_interes
     set calificacion_promedio = (
       select round(avg(calificacion)::numeric, 2)
         from visitas
        where punto_id = p_punto and calificacion is not null
     )
   where id = p_punto;
end;
$$;

grant execute on function public.calificar_punto(uuid, bigint, int) to authenticated;
