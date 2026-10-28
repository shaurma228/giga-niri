// Открытие окна в духе macOS: окно плавно вырастает из чуть меньшего размера,
// приподнимаясь и проявляясь. Без блика и эффектов — спокойно, как у Apple.
//
// coords_geo: координаты пикселя относительно окна (0..1), size_geo: размер окна в px.
// Цвет возвращается premultiplied.

vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;

    float scale = mix(0.9, 1.0, p);
    vec2 uv = (coords_geo.xy - 0.5) / scale + 0.5;
    uv.y += (1.0 - p) * 0.02;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(uv, 1.0)).st);
    return color * smoothstep(0.0, 0.6, p);
}
