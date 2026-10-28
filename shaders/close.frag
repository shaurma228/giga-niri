// Закрытие окна в духе macOS: окно сжимается к центру и быстро гаснет.

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;

    float scale = mix(1.0, 0.88, p);
    vec2 uv = (coords_geo.xy - 0.5) / scale + 0.5;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(uv, 1.0)).st);
    return color * (1.0 - smoothstep(0.0, 0.85, p));
}
