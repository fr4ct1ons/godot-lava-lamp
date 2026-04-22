shader_type spatial;
render_mode depth_draw_never;
render_mode blend_premul_alpha;

uniform vec3 color : source_color;
uniform vec3 emission : source_color;
uniform float unionSmoothness : hint_range(0.f, 1.f, 0.01f) = .5f;
uniform float surfaceRoughness : hint_range(0.f, 1.f, 0.01f) = .5f;

uniform vec3 liquidColor : source_color;
uniform float liquidAlpha : hint_range(0.f, 1.f, 0.01f) = .5f;

uniform vec4 sphereList[5];

varying vec3 vertexLocal;

void vertex() {
	// Called for every vertex the material is visible on.
	vertexLocal = VERTEX;
}

const float MAX_DIST = 100.0f;
const int MAX_STEPS = 100;
const float EPSILON = 0.0001f;

float opSmoothUnion( float shapeA, float shapeB, float smoothness )
{
	float k = max(smoothness, EPSILON) * 0.25f;
	float h = max(k-abs(shapeA - shapeB),0.0);
	return min(shapeA, shapeB) - h*h*0.25/k;
}

float SphereSDF( vec3 tracePos, vec3 spherePos, float radius)
{
	return length(tracePos - spherePos) - radius;
}

float CubeSDF( vec3 tracePos, vec3 spherePos, float radius) 
{
	vec3 q = abs(tracePos - spherePos) - vec3(radius);
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float SceneSDF(vec3 pos) 
{
	//float currentDist = sphereList[0].w - length(pos - sphereList[0].xyz);
	float currentDist = SphereSDF(pos, sphereList[0].xyz, sphereList[0].w);;
	for (int i = 1; i < 5; i++) 
	{
		
		float newDist = SphereSDF(pos, sphereList[i].xyz, sphereList[i].w);
		currentDist = opSmoothUnion(currentDist, newDist, unionSmoothness);
	}
	return currentDist;
}

float RaymarchV2(vec3 camPos, vec3 rayDir)
{
	float depth = 0.0;
	for (int i = 0; i < MAX_STEPS; i++) {
		
		vec3 pos = camPos + rayDir * depth;
		float dist = SceneSDF(pos);
		depth += dist;
		
		if (dist < EPSILON || depth > MAX_DIST) 
			break;
	}
	return depth;
}

vec3 EstimateNormals(vec3 pos) 
{
	return normalize( vec3(
		SceneSDF(vec3( pos.x + EPSILON, pos.yz ))
				- SceneSDF(vec3( pos.x - EPSILON, pos.yz)),
		SceneSDF( vec3( pos.x, pos.y + EPSILON, pos.z))
				- SceneSDF( vec3( pos.x, pos.y - EPSILON, pos.z )),
		SceneSDF( vec3(pos.xy, pos.z + EPSILON))
				- SceneSDF( vec3( pos.xy, pos.z - EPSILON ))
	));
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 cameraPos = INV_VIEW_MATRIX[3].xyz;
	vec3 cameraPosObject = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX[3].xyzw).xyz;
	
	vec3 rayDirection = normalize(vertexLocal - cameraPosObject);
	
	float depth = RaymarchV2( cameraPos, rayDirection);
	vec3 normalsWS = EstimateNormals(cameraPos + (rayDirection * depth));
	vec3 normalsVS = normalize(VIEW_MATRIX * vec4(normalsWS, 0.0f)).xyz;
	
	ALBEDO = (depth < MAX_DIST ? color : liquidColor);
	EMISSION = (depth < MAX_DIST ? emission * (1.0f - fresnel(0.4f, normalsVS, VIEW)) : vec3(0.0f));
	NORMAL = (depth < MAX_DIST ? normalsVS : NORMAL);
	ALPHA = (depth < MAX_DIST ? 1.0f : liquidAlpha);
	ROUGHNESS = (depth < MAX_DIST ? surfaceRoughness : 0.0f);
	//ALPHA_SCISSOR_THRESHOLD = 0.5f;
}
