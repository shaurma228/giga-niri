// Закрытие окна: «рассыпается на стекляшки».
// Окно распадается на квадратики 8×8 px снизу вверх (так выходит на экране)
// со случайным разбросом,
// по краю распада светится кайма в цветах рамки, окно слегка уменьшается.

float giga_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;

    float scale = mix(1.0, 0.96, p);
    vec2 uv = (coords_geo.xy - 0.5) / scale + 0.5;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(uv, 1.0)).st);

    // Порог распада для клетки: случайный, плюс сдвиг по высоте окна
    vec2 cell = floor(uv * size_geo.xy / 8.0);
    float t = giga_hash(cell + niri_random_seed * 17.0) * 0.55 + uv.y * 0.45;
    float edge = p * 1.12;

    float alive = smoothstep(edge, edge + 0.05, t);
    float glow = clamp(1.0 - abs(t - edge - 0.04) / 0.04, 0.0, 1.0);

    vec3 accent = mix(vec3(0.478, 0.635, 0.969), vec3(0.733, 0.604, 0.969), uv.x);
    color.rgb += accent * glow * 0.9 * color.a;

    return color * alive;
}
