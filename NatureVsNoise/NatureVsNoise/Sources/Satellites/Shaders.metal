#include <metal_stdlib>
using namespace metal;

// Satellite instance data
struct SatelliteInstanceData {
    float3 position;
    float4 color;
    float size;
    float brightness;
};

// Trail vertex data
struct TrailVertexData {
    float3 position;
    float4 color;
    float alpha;
};

// Vertex output for satellites (point sprites)
struct SatelliteVertexOut {
    float4 position [[position]];
    float4 color;
    float size;
    float brightness;
    float pointSize [[point_size]];
};

// Vertex output for trails
struct TrailVertexOut {
    float4 position [[position]];
    float4 color;
};

// Satellite vertex shader - renders points as sprites
vertex SatelliteVertexOut satelliteVertex(
    uint vertexID [[vertex_id]],
    constant SatelliteInstanceData* satellites [[buffer(0)]],
    constant float4x4& viewProjectionMatrix [[buffer(1)]]
) {
    SatelliteInstanceData sat = satellites[vertexID];

    SatelliteVertexOut out;
    out.position = viewProjectionMatrix * float4(sat.position, 1.0);
    out.color = sat.color;
    out.size = sat.size;
    out.brightness = sat.brightness;
    out.pointSize = sat.size * 100.0; // Scale point size

    return out;
}

// Satellite fragment shader - creates glowing point sprite
fragment float4 satelliteFragment(
    SatelliteVertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]]
) {
    // Create circular point sprite
    float dist = length(pointCoord - float2(0.5));
    if (dist > 0.5) {
        discard_fragment();
    }

    // Soft falloff for glow effect
    float alpha = 1.0 - smoothstep(0.0, 0.5, dist);
    alpha *= in.brightness;

    return float4(in.color.rgb, in.color.a * alpha);
}

// Trail vertex shader
vertex TrailVertexOut trailVertex(
    uint vertexID [[vertex_id]],
    constant TrailVertexData* trailVertices [[buffer(0)]],
    constant float4x4& viewProjectionMatrix [[buffer(1)]]
) {
    TrailVertexData trail = trailVertices[vertexID];

    TrailVertexOut out;
    out.position = viewProjectionMatrix * float4(trail.position, 1.0);
    out.color = trail.color;
    out.color.a *= trail.alpha;

    return out;
}

// Trail fragment shader
fragment float4 trailFragment(TrailVertexOut in [[stage_in]]) {
    return in.color;
}