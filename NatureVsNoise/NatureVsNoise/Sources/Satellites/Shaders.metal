#include <metal_stdlib>
using namespace metal;

// Orbital elements for GPU propagation
struct OrbitalElementsGPU {
    float epoch;
    float inclination;
    float raan;
    float eccentricity;
    float argumentOfPerigee;
    float meanAnomaly;
    float meanMotion;
    float bStar;
};

// Satellite instance data (matching Swift struct)
struct SatelliteInstanceData {
    float3 position;
    float3 velocity;
    float4 color;
    float size;
    float brightness;
    float2 _padding;
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

// Compute kernel for satellite propagation (simplified SGP4)
kernel void propagateSatellites(
    constant OrbitalElementsGPU* elements [[buffer(0)]],
    device SatelliteInstanceData* instances [[buffer(1)]],
    constant float4* colors [[buffer(2)]],
    constant float& time [[buffer(3)]],
    constant float& timeAcceleration [[buffer(4)]],
    uint id [[thread_position_in_grid]]
) {
    OrbitalElementsGPU el = elements[id];
    
    // Simplified orbital propagation (Keplerian)
    float t = time * timeAcceleration * 0.001; // Scale time
    float n = el.meanMotion * 2.0 * M_PI_F / 1440.0; // Convert to rad/min
    
    // Mean anomaly
    float M = el.meanAnomaly + n * t;
    
    // Simplified position (circular orbit approximation)
    float r = 6778.0; // Approx LEO altitude in km
    float x = r * cos(M + el.raan);
    float y = r * sin(M + el.raan);
    float z = r * sin(el.inclination) * sin(M + el.raan - el.argumentOfPerigee);
    
    // Scale to SceneKit units (6371 km = Earth radius = 2.0 SceneKit units)
    float scale = 2.0 / 6371.0;
    
    device SatelliteInstanceData& sat = instances[id];
    sat.position = float3(x * scale, z * scale, y * scale);
    sat.velocity = float3(-sin(M + el.raan), 0.0, cos(M + el.raan)) * n * r * scale;
}

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
    out.pointSize = sat.size * 80.0; // Scale point size for visibility

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