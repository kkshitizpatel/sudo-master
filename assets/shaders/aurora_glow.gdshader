shader_type canvas_item;

// Aurora Ambient Glow Shader (JK Games Sky Blue Edition)
// Procedural dynamic flowing dual-tone cosmic glow background
// Supports light canvas gradient (#EBF3FA -> #F8FAFC) and dark AMOLED void
// Godot 4.7 GDScript / Shading Language Compliant

uniform vec4 color_bg : source_color = vec4(0.922, 0.953, 0.980, 1.0); // Top: Soft Ice Blue #EBF3FA
uniform vec4 color_bg_bottom : source_color = vec4(0.973, 0.980, 0.988, 1.0); // Bottom: Off-White Slate #F8FAFC
uniform vec4 color_primary : source_color = vec4(0.114, 0.306, 0.847, 1.0); // Theme Accent: Royal Blue #1D4ED8
uniform vec4 color_secondary : source_color = vec4(0.220, 0.741, 0.973, 1.0); // Secondary Glow: Sky Cyan #38BDF8
uniform float flow_speed : hint_range(0.01, 1.0) = 0.10;
uniform float intensity : hint_range(0.0, 2.0) = 0.65;
uniform bool is_dark = false;

// Hash and smooth noise helpers
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
    vec2 uv = UV;
    float t = TIME * flow_speed;
    
    // Wave 1: Primary organic blob (upper-left to center)
    vec2 p1 = uv - vec2(0.35 + sin(t * 0.7) * 0.15, 0.30 + cos(t * 0.5) * 0.15);
    float dist1 = length(p1 * vec2(1.0, 1.2));
    float blob1 = exp(-dist1 * 2.8);
    
    // Wave 2: Secondary organic blob (lower-right to center)
    vec2 p2 = uv - vec2(0.68 + cos(t * 0.6) * 0.18, 0.72 + sin(t * 0.8) * 0.14);
    float dist2 = length(p2 * vec2(1.2, 0.9));
    float blob2 = exp(-dist2 * 2.6);
    
    // Wave 3: Ambient flowing ribbon in middle
    float ribbon = sin(uv.x * 3.5 + uv.y * 2.0 + t * 1.2) * 0.5 + 0.5;
    ribbon *= exp(-abs(uv.y - 0.5) * 3.0);
    
    // Linear canvas gradient from top to bottom
    vec3 base_canvas = mix(color_bg.rgb, color_bg_bottom.rgb, uv.y);
    vec3 col;
    
    if (is_dark) {
        col = base_canvas;
        col += color_primary.rgb * (blob1 * intensity * 0.85);
        col += color_secondary.rgb * (blob2 * intensity * 0.75);
        col += mix(color_primary.rgb, color_secondary.rgb, 0.5) * (ribbon * intensity * 0.35);
    } else {
        // Soft vibrant ambient sky glow for light themes
        col = base_canvas;
        col = mix(col, color_secondary.rgb, blob1 * intensity * 0.28);
        col = mix(col, color_primary.rgb, blob2 * intensity * 0.15);
        col = mix(col, mix(color_primary.rgb, color_secondary.rgb, 0.5), ribbon * intensity * 0.15);
    }
    
    // Very delicate dithering to eliminate banding without dirty paper look
    float grain = (hash(uv + fract(vec2(t))) - 0.5) * 0.004;
    col += vec3(grain);
    COLOR = vec4(col, 1.0);
}
