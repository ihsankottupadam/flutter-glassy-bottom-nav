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
uniform float uRadius;     // corner radius, device pixels
uniform float uBandWidth;  // how far in from the edge the bending reaches
uniform float uAmount;     // how far the sampled pixels travel

uniform sampler2D uContent;

out vec4 fragColor;

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

void main() {
    vec2 frag = FlutterFragCoord().xy;

    vec2 center = (uBarRect.xy + uBarRect.zw) * 0.5;
    vec2 halfSize = (uBarRect.zw - uBarRect.xy) * 0.5;
    vec2 p = frag - center;

    float sd = sdRoundedRect(p, halfSize, uRadius);

    // Outside the bar, and inside its untouched middle: one read, no work.
    if (sd > 0.0 || -sd >= uBandWidth) {
        fragColor = sampleAt(frag);
        return;
    }

    // Strongest at the very edge, zero at the band's inner limit, ramped on a
    // quarter circle so the bending eases off rather than stopping abruptly.
    float t = 1.0 - (-sd / uBandWidth);
    float d = (1.0 - sqrt(max(0.0, 1.0 - t * t))) * uAmount;

    fragColor = sampleAt(frag - d * gradSdRoundedRect(p, halfSize, uRadius));
}
