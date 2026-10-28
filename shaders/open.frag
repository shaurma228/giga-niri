// Открытие окна: «стекло проявляется».
// Окно чуть увеличивается и поднимается снизу, проявляясь из прозрачности,
// а по нему наискосок проходит блик в цветах рамки (#7aa2f7 → #bb9af7).
//
// coords_geo: координаты пикселя относительно окна (0..1), size_geo: размер окна в px.
// Цвет возвращается premultiplied.

vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;

    float scale = mix(0.93, 1.0, p);
    vec2 uv = (coords_geo.xy - 0.5) / scale + 0.5;
    uv.y += (1.0 - p) * 0.035;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(uv, 1.0)).st);

    // Блик: диагональная полоса пробегает от левого верхнего угла к правому нижнему
    float d = (uv.x + uv.y) * 0.5;
    float band = smoothstep(0.14, 0.0, abs(d - (p * 1.5 - 0.25)));
    vec3 accent = mix(vec3(0.478, 0.635, 0.969), vec3(0.733, 0.604, 0.969), uv.x);
    color.rgb += accent * band * 0.45 * color.a * (1.0 - p * 0.6);

    return color * p;
}
