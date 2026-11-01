shader_type canvas_item;

// Real-Time Frosted Glass Backdrop Blur Shader
// Godot 4.7 GDScript / Shading Language Compliant
// Uses hint_screen_texture with multi-tap sampling and luminous border highlights

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 glass_tint : source_color = vec4(0.059, 0.090, 0.165, 0.72); // rgba(15, 23, 42, 0.72)
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.12);
uniform float border_width : hint_range(0.0, 0.1) = 0.005;
uniform float corner_radius : hint_range(0.0, 0.5) = 0.04;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.15;

// Signed Distance Field for Rounded Rectangle
float rounded_rect_sdf(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
    vec2 half_size = vec2(0.5);
    vec2 p = UV - half_size;
    float d = rounded_rect_sdf(p, half_size, corner_radius);
    
    // Mask out pixels outside rounded corners
    float alpha_mask = 1.0 - smoothstep(0.0, 0.005, d);
    if (alpha_mask <= 0.001) {
        discard;
    }
    
    // Multi-tap screen blur (9-tap kernel)
    vec2 pixel_size = SCREEN_PIXEL_SIZE * blur_amount;
    vec4 blurred = vec4(0.0);
    blurred += texture(screen_texture, SCREEN_UV + vec2(-pixel_size.x, -pixel_size.y)) * 0.075;
    blurred += texture(screen_texture, SCREEN_UV + vec2( 0.0,          -pixel_size.y)) * 0.125;
    blurred += texture(screen_texture, SCREEN_UV + vec2( pixel_size.x, -pixel_size.y)) * 0.075;
    
    blurred += texture(screen_texture, SCREEN_UV + vec2(-pixel_size.x,  0.0))          * 0.125;
    blurred += texture(screen_texture, SCREEN_UV)                                      * 0.200;
    blurred += texture(screen_texture, SCREEN_UV + vec2( pixel_size.x,  0.0))          * 0.125;
    
    blurred += texture(screen_texture, SCREEN_UV + vec2(-pixel_size.x,  pixel_size.y)) * 0.075;
    blurred += texture(screen_texture, SCREEN_UV + vec2( 0.0,           pixel_size.y)) * 0.125;
    blurred += texture(screen_texture, SCREEN_UV + vec2( pixel_size.x,  pixel_size.y)) * 0.075;
    
    // Frosted glass tint blending
    vec3 composite = mix(blurred.rgb, glass_tint.rgb, glass_tint.a);
    
    // Subtle top-left specular sheen
    float sheen = clamp((1.0 - UV.y) * 0.5 + (1.0 - UV.x) * 0.2, 0.0, 1.0);
    composite += vec3(sheen * specular_intensity);
    
    // 1px luminous outer border
    float border_mask = smoothstep(border_width, 0.0, abs(d));
    composite = mix(composite, border_color.rgb, border_mask * border_color.a * 3.0);
    
    COLOR = vec4(composite, alpha_mask);
}
