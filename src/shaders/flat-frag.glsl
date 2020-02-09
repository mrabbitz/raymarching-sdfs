#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;


const int MAX_MARCHING_STEPS = 256;
const float EPSILON = 0.001;

const float k_coeff = 0.1;

vec3 l0 = vec3(-3.0, 0.0, 0.0);
vec3 l1 = vec3(-3.0, 0.5, 0.0);
vec3 l2 = vec3(0.0, 0.0, 0.0);
vec3 l3 = vec3(0.0, 0.5, 0.0);
vec3 l4 = vec3(-2.0, 0.0, 0.0);
vec3 l5 = vec3(-2.0, 0.5, 0.0);

//const vec3 spheres[6] = vec3[6](l0, l1, l2, l3, l4, l5);

struct Intersection {
    vec3 p;
    vec3 normal;
    float t;
    int objHit;
};

vec3 rotateX(vec3 p, float a) {
    return vec3(p.x, cos(a) * p.y - sin(a) * p.z, sin(a) * p.y + cos(a) * p.z);
}
    
vec3 rotateY(vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.z, p.y, -sin(a) * p.x + cos(a) * p.z);
}

vec3 rotateZ(vec3 p, float a) {
    return vec3(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y, p.z);
}

float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

// polynomial smooth min (k = 0.1);
float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

// point, radius, center
float SphereSDF(vec3 p, float r, vec3 c) {
    return distance(p, c) - r;
}

float SceneSDF(in vec3 pos) {
  float s0 = SphereSDF(pos, 0.5, l0);
  float s1 = SphereSDF(pos, 0.5, l1);
  float s2 = SphereSDF(pos, 0.5, l2);
  float s3 = SphereSDF(pos, 0.5, l3);
  float s4 = SphereSDF(pos, 0.5, l4);
  float s5 = SphereSDF(pos, 0.5, l5);

  float c0 = opSmoothIntersection(s0, s1, k_coeff);
  float c1 = opSmoothSubtraction(s2, s3, k_coeff);
  float c2 = sminCubic(s4, s5, k_coeff);
	
  return min(c0, min(c1, c2));
}

float SceneSDF(in vec3 pos, out int objHit) {
  float s0 = SphereSDF(pos, 0.5, l0);
  float s1 = SphereSDF(pos, 0.5, l1);
  float s2 = SphereSDF(pos, 0.5, l2);
  float s3 = SphereSDF(pos, 0.5, l3);
  float s4 = SphereSDF(pos, 0.5, l4);
  float s5 = SphereSDF(pos, 0.5, l5);

  float c0 = opSmoothIntersection(s0, s1, k_coeff);
  float c1 = opSmoothSubtraction(s2, s3, k_coeff);
  float c2 = sminCubic(s4, s5, k_coeff);
	
  float t = c0;
  objHit = 0;

  if (c1 < t) {
    t = c1;
    objHit = 1;
  }
  if (c2 < t) {
    t = c2;
    objHit = 2;
  }

  return t;
}

// float SceneSDF(in vec3 pos) {
//   float t = SphereSDF(pos, 0.5, spheres[0]);
//   for (int i = 1; i < spheres.length(); i++) {
//     t = min(t, SphereSDF(pos, 0.5, spheres[i]));
//   }
//   return t;
// }

// float SceneSDF(in vec3 pos, out int objHit) {
  
//   float t = SphereSDF(pos, 0.5, spheres[0]);
//   objHit = 0;

//   for (int i = 1; i < spheres.length(); i++) {
//     float temp = SphereSDF(pos, 0.5, spheres[i]);
//     if (temp < t) {
//       t = temp;
//       objHit = i;
//     }
//   }
//   return t;
// }

// float SceneSDF(in vec3 pos) {
//   float t = min(SphereSDF(pos, 0.5, center_sphere), SphereSDF(pos, 0.5, right_sphere));
//   t = min(t, SphereSDF(pos, 0.5, left_sphere));
//   return min(t, SphereSDF(pos, 0.5, up_sphere));
// }

// float SceneSDF(in vec3 pos, out int objHit) {
//   float s0 = SphereSDF(pos, 0.5, center_sphere);
//   float s1 = SphereSDF(pos, 0.5, right_sphere);
//   float s2 = SphereSDF(pos, 0.5, left_sphere);
//   float s3 = SphereSDF(pos, 0.5, up_sphere);
	
//   float t = s0;
//   objHit = 0;

//   if (s1 < t) {
//     t = s1;
//     objHit = 1;
//   }
//   if (s2 < t) {
//     t = s2;
//     objHit = 2;
//   }
//   if (s3 < t) {
//     t = s3;
//     objHit = 3;
//   }

//   return t;
// }

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

bool ShadowTest(vec3 p) {

  bool returnVal = false;

  vec3 rayDirection = normalize(vec3(0.0, 0.0, 0.0) - p);
  float lengthBetweenPointAndLight = length(vec3(0.0, 0.0, 0.0) - p);

  vec3 shadowRayayOrigin = p + rayDirection;
  vec3 shadowRayayDirection = rayDirection;

  int objHit = -1;
  float t = -1.0;
  t = RayMarch(shadowRayayOrigin, shadowRayayDirection, objHit);

  if (objHit != -1) {
    if (t < lengthBetweenPointAndLight) {
      returnVal = true;
    }
  }

  return returnVal;
}

vec3 ComputeColor(vec3 p, vec3 n, int objHit) {
  vec3 color;
  if (objHit == 0) {
    color = vec3(1.0, 0.0, 0.0);
  }
  else if (objHit == 1) {
    return vec3(1.0, 77.0/255.0, 0.0);
  }
  else if (objHit == 2) {
    color = vec3(0.0, 0.0, 1.0);
  }
  else {
    return vec3(0.0, 0.0, 0.0);
  }

  vec3 sumLightColors = vec3(0.0);

  if(!ShadowTest(p)) {

    vec3 lightVec = normalize(vec3(0.0, 0.0, 0.0) - p);

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = clamp(dot(n, lightVec), 0.0, 1.0);    // Avoid negative lighting values with clamp

    sumLightColors += vec3(1.0, 1.0, 1.0) * diffuseTerm;
  }

  return color * sumLightColors;
}


vec3 ComputeNormal(vec3 pos) {
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

  // l0 = rotateY(l0, rotation);
  // l1 = rotateY(l1, rotation);
  // l2 = rotateX(l2, rotation);
  // l3 = rotateX(l3, rotation);
  // l4 = rotateZ(l4, rotation);
  // l5 = rotateZ(l5, rotation);


  vec3 rayOrigin;
  vec3 rayDirection;
  RayCast(rayOrigin, rayDirection, 45.f);

  Intersection intersection = SceneIntersection(rayOrigin, rayDirection);

  if (intersection.objHit != -1)
  {
    // vec3 vectorOfOnes = vec3(1.0);
    // out_Col = vec4((intersection.normal + vectorOfOnes) * 0.5, 1.0);

    out_Col = vec4(ComputeColor(intersection.p, intersection.normal, intersection.objHit), 1.0);
  }
  else
  {
    out_Col = vec4(0.0, 0.0, 0.0, 1.0);
    //out_Col = vec4(vec3(0.5 * (rayDirection + vec3(1.0, 1.0, 1.0))), 1.0);
  }

  //out_Col = vec4(0.5 * (fs_Pos + vec2(1.0)), 0.5 * (sin(u_Time * 3.14159 * 0.01) + 1.0), 1.0);
}
