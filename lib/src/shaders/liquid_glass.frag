#version 460 core

// The rim refraction of GlassStyle.liquid.
//
// Runs as the filter of a full-screen BackdropFilter sitting above the bar's
// own blur, so its input is the whole screen with the blurred bar already in
// it. It is told where the bar is rather than being handed a texture cropped
// to it: uBarRect is in the same device-pixel space as FlutterFragCoord(),
// which is what lets the shader mask itself and leaves everything outside the
// bar exactly as it was.
//
// That self-masking is the whole economy of it. Every pixel outside the shape,
// and every pixel deeper into the bar than the rim band, costs one texture
// read and nothing else.
//
// The SDF and its gradient are from iquilezles.org/articles/distfunctions2d.

#include <flutter/runtime_effect.glsl>

precision highp float;

// Engine-set to the size of the bound input texture. Must be the first
// uniform and must be a vec2 -- see ImageFilter.shader in dart:ui.
uniform vec2 uTextureSize;

uniform vec4 uBarRect;     // left, top, right, bottom, in device pixels
uniform vec4 uCornerRadii; // topLeft, topRight, bottomRight, bottomLeft
uniform float uBandWidth;  // how far in from the edge the bending reaches
uniform float uAmount;     // how far the sampled pixels travel
uniform float uRimWidth;   // how thick the lit edge is
uniform float uRimOpacity; // how much light that edge catches

uniform sampler2D uContent;

out vec4 fragColor;

/// The radius of whichever corner [p] is nearest, [p] being centred on the
/// shape. GlassyNavbarType.bottom rounds only its top corners, so one radius
/// for the whole rect would refract a curve the bar does not have.
float radiusAt(vec2 p, vec4 radii) {
    return p.x < 0.0
        ? (p.y < 0.0 ? radii.x : radii.w)
        : (p.y < 0.0 ? radii.y : radii.z);
}

float sdRoundedRect(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

/// The outward normal: the gradient of the distance field above.
vec2 gradSdRoundedRect(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    vec2 s = sign(p);
    if (max(q.x, q.y) > 0.0) {
        return s * normalize(max(q, vec2(0.0)));
    }
    return q.x > q.y ? vec2(s.x, 0.0) : vec2(0.0, s.y);
}

// No y flip. ImageFilter.shader hands the input over in the same orientation
// as FlutterFragCoord(), including on the GLES backend where
// IMPELLER_TARGET_OPENGLES is defined.
vec4 sampleAt(vec2 deviceCoord) {
    return texture(uContent, deviceCoord / uTextureSize);
}

/// How much light the rim catches where its outward normal is [n].
///
/// The light is overhead, so the top edge is brightest. The floor is not
/// zero and the bottom lip is lit more than the sides: a rim that faded to
/// nothing along the caps would read as two lit strips rather than as one
/// piece of glass, and real glass bounces some light back up off whatever it
/// is sitting on.
float rimFacing(vec2 n) {
    float up = -n.y;
    return 0.25 + 0.55 * max(up, 0.0) + 0.25 * max(-up, 0.0);
}

void main() {
    vec2 frag = FlutterFragCoord().xy;

    vec2 center = (uBarRect.xy + uBarRect.zw) * 0.5;
    vec2 halfSize = (uBarRect.zw - uBarRect.xy) * 0.5;
    vec2 p = frag - center;

    // Clamped the way Flutter clamps an RRect whose radii do not fit: the
    // pill's 50 is wider than a 33-high half-bar, and an unclamped radius
    // puts the SDF's zero line inside the ClipRRect's curve, which shows as
    // the rim sliding off the shape at the caps.
    float radius = min(radiusAt(p, uCornerRadii), min(halfSize.x, halfSize.y));
    float sd = sdRoundedRect(p, halfSize, radius);

    // Kept to half the bar's shortest half-axis, so a short bar -- one built
    // without labels, or with tight padding -- narrows its rim instead of
    // having the two bevels meet in the middle and lose its flat centre. The
    // travel shrinks with it, so a narrowed rim bends less rather than
    // bending the same distance through less glass.
    float limit = min(halfSize.x, halfSize.y) * 0.5;
    float band = min(uBandWidth, limit);
    float amount = uAmount * (band / max(uBandWidth, 1.0));

    // Outside the bar, and inside its untouched middle: one read, no work.
    if (sd > 0.0 || -sd >= band) {
        fragColor = sampleAt(frag);
        return;
    }

    // Strongest at the very edge, zero at the band's inner limit, ramped on a
    // quarter circle so the bending eases off rather than stopping abruptly.
    float t = 1.0 - (-sd / band);
    float d = (1.0 - sqrt(max(0.0, 1.0 - t * t))) * amount;

    vec2 normal = gradSdRoundedRect(p, halfSize, radius);
    vec4 color = sampleAt(frag - d * normal);

    // The lit edge, added over the bent pixels rather than bent with them.
    // This is the half of Apple's rim that stays crisp: the refraction moves
    // what is behind the glass, the highlight sits on the glass itself. It
    // needs no clipping of its own -- uRimWidth is far inside uBandWidth, so
    // the early-out above still bounds it, and the ClipRRect the bar is
    // already wrapped in cuts its outer side on exactly the curve the SDF
    // measures from.
    float lit = (1.0 - smoothstep(0.0, uRimWidth, -sd)) * rimFacing(normal);

    // Additive, and kept premultiplied: rgb may not exceed alpha.
    color.rgb = min(color.rgb + lit * uRimOpacity * color.a, vec3(color.a));
    fragColor = color;
}
