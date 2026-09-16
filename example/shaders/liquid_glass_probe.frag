#version 460 core

// Probe: can a rounded-rect refraction be anchored inside a *plain*
// BackdropFilter, with no OffsetLayer.toImageSync capture of the source?
//
// The premise fluid_glass rejected (draw_backdrop.dart:770) is that "a fragment
// shader in a backdrop filter is handed the whole screen rather than the
// element's texture, so the lens would have nothing to anchor its geometry to".
// That is true of the texture, and it is only fatal if the geometry has to come
// *from* the texture. Here it does not: the bar's rect is passed in as a
// uniform in the same space as FlutterFragCoord(), so the shader knows where
// the bar is without being handed a texture cropped to it.
//
// Everything outside the shape is returned untouched, so a full-screen input is
// harmless -- the shader masks itself.

#include <flutter/runtime_effect.glsl>

precision highp float;

// Engine-set to the size of the bound input texture. MUST be the first uniform
// and a vec2 (dart:ui painting.dart:4425).
uniform vec2 uTextureSize;

// The bar, in the same coordinate space as FlutterFragCoord(): device pixels.
uniform vec4 uBarRect;      // left, top, right, bottom
uniform float uRadius;      // corner radius
uniform float uBandWidth;   // how far in from the edge the bending reaches
uniform float uAmount;      // how far the sampled pixels travel
uniform float uDebug;       // >0.5 paints the band instead of refracting

uniform sampler2D uContent;

out vec4 fragColor;

// iquilezles.org/articles/distfunctions2d
float sdRoundedRect(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Outward normal: the gradient of the SDF above.
vec2 gradSdRoundedRect(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    vec2 s = sign(p);
    if (max(q.x, q.y) > 0.0) {
        return s * normalize(max(q, vec2(0.0)));
    }
    return q.x > q.y ? vec2(s.x, 0.0) : vec2(0.0, s.y);
}

// No y flip. fluid_glass verified (refraction.frag) that ImageFilter.shader
// hands the input over in the same orientation as FlutterFragCoord(), even on
// the GLES backend where IMPELLER_TARGET_OPENGLES is defined.
vec4 sampleAt(vec2 deviceCoord) {
    return texture(uContent, deviceCoord / uTextureSize);
}

void main() {
    vec2 frag = FlutterFragCoord().xy;

    vec2 center = (uBarRect.xy + uBarRect.zw) * 0.5;
    vec2 halfSize = (uBarRect.zw - uBarRect.xy) * 0.5;
    vec2 p = frag - center;

    float sd = sdRoundedRect(p, halfSize, uRadius);

    if (uDebug > 0.5) {
        // Outside the shape, pass through, so the bar's true edge stays
        // visible underneath and any mismatch is obvious.
        if (sd > 0.0) {
            fragColor = sampleAt(frag);
            return;
        }
        // Inside: red at the very edge fading to blue at the band's inner
        // limit, then flat green across the untouched interior. If the shader
        // is anchored correctly this traces the bar's rounded rect exactly.
        float t = clamp(-sd / uBandWidth, 0.0, 1.0);
        vec3 band = t >= 1.0
            ? vec3(0.1, 0.8, 0.3)
            : mix(vec3(1.0, 0.15, 0.2), vec3(0.2, 0.4, 1.0), t);
        fragColor = vec4(band, 1.0);
        return;
    }

    // The two early-outs that keep this cheap: everything outside the bar, and
    // everything deeper than the rim band, is one texture read.
    if (sd > 0.0 || -sd >= uBandWidth) {
        fragColor = sampleAt(frag);
        return;
    }

    // Ramp the displacement so it is strongest at the very edge and zero at the
    // band's inner limit -- a quarter circle, as in fluid_glass's circleMap.
    float t = 1.0 - (-sd / uBandWidth);
    float d = (1.0 - sqrt(max(0.0, 1.0 - t * t))) * uAmount;

    vec2 n = gradSdRoundedRect(p, halfSize, uRadius);
    fragColor = sampleAt(frag - d * n);
}
