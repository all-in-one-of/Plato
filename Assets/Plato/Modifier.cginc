#include "UnityCG.cginc"
#include "SimplexNoise3D.cginc"

half3 _AlbedoColor;

half _Metallic;
half _Smoothness;

sampler2D _NormalMap;

sampler2D _OcclusionMap;
half _OcclusionStrength;

sampler2D _DetailAlbedoMap;
sampler2D _DetailNormalMap;
half _DetailNormalMapScale;

struct Input
{
    float2 uv_NormalMap;
    float cutParam;
};

float UVRandom(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float3 ApplyModifier(float3 v)
{
    float3 np = v * 3;
    np += _Time.y * 0.5;
    //np = floor(np * 5) / 5;

    float disp = snoise(np);
    float scale = 1 + 0.8 * disp;

    float3 center = float3(0, 0.46, 0);
    center.y = v.y;

    return (v - center) * scale + center;
}

void ModifyVertex(inout appdata_full v, out Input o)
{
    UNITY_INITIALIZE_OUTPUT(Input, o);

    float3 v1 = ApplyModifier(v.vertex.xyz);
    float3 v2 = ApplyModifier(v.texcoord1.xyz);
    float3 v3 = ApplyModifier(v.texcoord2.xyz);

    v.vertex.xyz = v1;
    v.normal = normalize(lerp(v.normal, normalize(cross(v2 - v1, v3 - v1)), 0.5));
//    v.normal = normalize(cross(v2 - v1, v3 - v1));

#ifdef SURFACE_FLIP
    v.normal *= -1;
#endif

    o.cutParam = dot(v.vertex, normalize(float3(0.1, 1, 0.1))) * 8 + _Time.y * 2;
}

void Surface(Input IN, inout SurfaceOutputStandard o)
{
    clip(frac(IN.cutParam) - 0.4);

#ifndef MATERIAL_BACK

    half4 a_map = tex2D(_DetailAlbedoMap, IN.uv_NormalMap);

    o.Albedo = saturate(_AlbedoColor.rgb * a_map);
    o.Metallic = _Metallic;
    o.Smoothness = _Smoothness;

    half4 n1_map = tex2D(_NormalMap, IN.uv_NormalMap);
    half4 n2_map = tex2D(_DetailNormalMap, IN.uv_NormalMap);
    half3 n1 = UnpackNormal(n1_map);
    half3 n2 = UnpackScaleNormal(n2_map, _DetailNormalMapScale);
    o.Normal = BlendNormals(n1, n2);

    half o_map = tex2D(_OcclusionMap, IN.uv_NormalMap).g;
    o.Occlusion = LerpOneTo(o_map, _OcclusionStrength);

#else

    o.Albedo = float3(1, 0, 0);
    o.Normal = float3(0, 0, -1);

#endif
}