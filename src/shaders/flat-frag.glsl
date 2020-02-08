#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;


const int MAX_MARCHING_STEPS = 256;
const float EPSILON = 0.001;

vec3 center_sphere = vec3(0.0, 0.0, 0.0);
vec3 right_sphere = vec3(5.0, 0.0, 0.0);
vec3 left_sphere = vec3(-5.0, 0.0, 0.0);
vec3 up_sphere = vec3(0.0, 5.0, 0.0);


vec3 rotateX(vec3 p, float a) {
    return vec3(p.x, cos(a) * p.y - sin(a) * p.z, sin(a) * p.y + cos(a) * p.z);
}
    
vec3 rotateY(vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.z, p.y, -sin(a) * p.x + cos(a) * p.z);
}

vec3 rotateZ(vec3 p, float a) {
    return vec3(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y, p.z);
}

struct Intersection {
    vec3 p;
    vec3 normal;
    float t;
    int objHit;
};

// point, radius, center
float SphereSDF(vec3 p, float r, vec3 c) {
    return distance(p, c) - r;
}

float SceneSDF(in vec3 pos) {
  float t = min(SphereSDF(pos, 0.5, center_sphere), SphereSDF(pos, 0.5, right_sphere));
  t = min(t, SphereSDF(pos, 0.5, left_sphere));
  return min(t, SphereSDF(pos, 0.5, up_sphere));
}

float SceneSDF(in vec3 pos, out int objHit) {
  float s0 = SphereSDF(pos, 0.5, center_sphere);
  float s1 = SphereSDF(pos, 0.5, right_sphere);
  float s2 = SphereSDF(pos, 0.5, left_sphere);
  float s3 = SphereSDF(pos, 0.5, up_sphere);
	
  float t = s0;
  objHit = 0;

  if (s1 < t) {
    t = s1;
    objHit = 1;
  }
  if (s2 < t) {
    t = s2;
    objHit = 2;
  }
  if (s3 < t) {
    t = s3;
    objHit = 3;
  }

  return t;
}

float RayMarch(in vec3 eye, in vec3 viewRayDirection, out int objHit) {
  float marchedDist = 0.0;
  float minDist = 0.0;
  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
      minDist = SceneSDF(eye + marchedDist * viewRayDirection, objHit);
      if (minDist < EPSILON) {
          // We're inside the scene surface!
          return marchedDist;
      }
      // Move along the view ray
      marchedDist += minDist;
  }
  objHit = -1;
  return -1.0;
}

vec3 ComputeNormal(vec3 pos)
{
    vec2 offset = vec2(0.0, 0.001);
    return normalize( vec3( SceneSDF(pos + offset.yxx) - SceneSDF(pos - offset.yxx),
                            SceneSDF(pos + offset.xyx) - SceneSDF(pos - offset.xyx),
                            SceneSDF(pos + offset.xxy) - SceneSDF(pos - offset.xxy)
                          )
                    );
}

Intersection SceneIntersection(in vec3 eye, in vec3 viewRayDirection) {
  int objHit = -1;
  float t = -1.0;
  t = RayMarch(eye, viewRayDirection, objHit);

  if (objHit == -1)
  {
    return Intersection(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), t, objHit);
  }
  else
  {
    vec3 intersectPoint = eye + t * viewRayDirection;
    vec3 intersectNormal = ComputeNormal(intersectPoint);
    return Intersection(intersectPoint, intersectNormal, t, objHit);
  }
}


void RayCast(out vec3 origin, out vec3 direction, in float foyY) {
  vec3 Forward = normalize(u_Ref - u_Eye);
  vec3 Right = normalize(cross(Forward, u_Up));

  float tanFovY = tan(foyY / 2.0);
  float len = length(u_Ref - u_Eye);
  float aspect = u_Dimensions.x / u_Dimensions.y;

  vec3 V = u_Up * len * tanFovY;
  vec3 H = Right * len * aspect * tanFovY;

  vec3 p = u_Ref + fs_Pos.x * H + fs_Pos.y * V;

  origin = u_Eye;
  direction = normalize(p - u_Eye);
}

void main() {

  float rotation = u_Time * 3.14159 * 0.01;
  float rotation1 = rotation * 1.5;
  float rotation2 = rotation / 1.5;


  //center_sphere = rotateZ(center_sphere, rotation);
  //right_sphere = rotateZ(right_sphere, rotation2);
  //left_sphere = rotateZ(left_sphere, rotation1);
  //up_sphere = rotateZ(up_sphere, rotation);


  vec3 rayOrigin;
  vec3 rayDirection;
  RayCast(rayOrigin, rayDirection, 45.f);

  Intersection intersection = SceneIntersection(rayOrigin, rayDirection);

  if (intersection.objHit != -1)
  {
    vec3 vectorOfOnes = vec3(1.0);
    out_Col = vec4((intersection.normal + vectorOfOnes) * 0.5, 1.0);
  }
  else
  {
    out_Col = vec4(0.0, 0.0, 0.0, 1.0);
    //out_Col = vec4(vec3(0.5 * (rayDirection + vec3(1.0, 1.0, 1.0))), 1.0);
  }

  //out_Col = vec4(0.5 * (fs_Pos + vec2(1.0)), 0.5 * (sin(u_Time * 3.14159 * 0.01) + 1.0), 1.0);
}
