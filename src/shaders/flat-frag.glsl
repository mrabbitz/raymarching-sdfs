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

vec3 l0 = vec3(-6.0, 0.0, 0.0);
vec3 l1 = vec3(-6.0, 0.5, 0.0);
vec3 l2 = vec3(5.0, 0.0, 0.0);
vec3 l3 = vec3(5.0, 0.5, 0.0);
vec3 l4 = vec3(-5.0, 0.0, 0.0);
vec3 l5 = vec3(-5.0, 0.5, 0.0);

//const vec3 spheres[6] = vec3[6](l0, l1, l2, l3, l4, l5);

vec3 sunPos = vec3(0.0, 0.0, 0.0);
float sunRadius = 2.0;

vec3 sunHueAndIntensity = vec3(2.0, 2.0, 2.0);

vec3 earthPos = vec3(-3.5, 0.0, 0.0);
float earthRadius = 0.5;

vec2 earthOffset = vec2(0.0, 0.2);

vec3 moonPos = vec3(-1, 0.0, 0.0);
float moonRadius = 0.3;
float moonCraterRadius = 0.1;

struct Intersection {
    vec3 p;
    vec3 normal;
    float t;
    int objHit;
};

float random1o3i(vec3 p) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 191.999))) * 43758.5453);
}

float noise1D(float x) {
    return fract((1.0 - float(x * (x * x * 15731.0 + 789221.0)
            + 1376312589.0))
            / 10737741824.0);
}

float random1o2i( vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 random3o3i(vec3 p) {
  return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 191.999)),
                        dot(p, vec3(269.5, 183.3, 765.54)),
                        dot(p, vec3(420.69, 631.2, 109.21))))
                        * 43758.5453);
}

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

  float sun = SphereSDF(pos, sunRadius, sunPos);

  float earth = SphereSDF(pos, earthRadius, earthPos - earthOffset.yxx);
  float earth1 = SphereSDF(pos, earthRadius, earthPos + earthOffset.yxx);
  float earth2 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xyx);
  float earth3 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xxy);
  float earth4 = SphereSDF(pos, earthRadius, earthPos - earthOffset.xyx);

  earth = sminCubic(earth, earth1, k_coeff);
  earth2 = sminCubic(earth2, earth3, k_coeff);

  earth = sminCubic(earth, earth2, k_coeff);
  earth = sminCubic(earth, earth4, k_coeff);

  float moon = SphereSDF(pos, moonRadius, moonPos);
  float crater1 = SphereSDF(pos, moonCraterRadius, moonPos + vec3(moonRadius / 2.0));
  moon = opSubtraction(crater1, moon);

	
  return min(moon, min(earth, min(sun, min(c0, min(c1, c2)))));
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

  float sun = SphereSDF(pos, sunRadius, sunPos);

  float earth = SphereSDF(pos, earthRadius, earthPos - earthOffset.yxx);
  float earth1 = SphereSDF(pos, earthRadius, earthPos + earthOffset.yxx);
  float earth2 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xyx);
  float earth3 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xxy);
  float earth4 = SphereSDF(pos, earthRadius, earthPos - earthOffset.xyx);

  earth = sminCubic(earth, earth1, k_coeff);
  earth2 = sminCubic(earth2, earth3, k_coeff);

  earth = sminCubic(earth, earth2, k_coeff);
  earth = sminCubic(earth, earth4, k_coeff);

  float moon = SphereSDF(pos, moonRadius, moonPos);
  float crater1 = SphereSDF(pos, moonCraterRadius, moonPos + vec3(moonRadius / 2.0));
  moon = opSubtraction(crater1, moon);
	
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
  if (sun < t) {
    t = sun;
    objHit = 3;
  }
  if (earth < t) {
    t = earth;
    objHit = 4;
  }
  if (moon < t) {
    t = moon;
    objHit = 5;
  }

  return t;
}

float ShadowSceneSDF(in vec3 pos) {
  float s0 = SphereSDF(pos, 0.5, l0);
  float s1 = SphereSDF(pos, 0.5, l1);
  float s2 = SphereSDF(pos, 0.5, l2);
  float s3 = SphereSDF(pos, 0.5, l3);
  float s4 = SphereSDF(pos, 0.5, l4);
  float s5 = SphereSDF(pos, 0.5, l5);

  float c0 = opSmoothIntersection(s0, s1, k_coeff);
  float c1 = opSmoothSubtraction(s2, s3, k_coeff);
  float c2 = sminCubic(s4, s5, k_coeff);

  float earth = SphereSDF(pos, earthRadius, earthPos - earthOffset.yxx);
  float earth1 = SphereSDF(pos, earthRadius, earthPos + earthOffset.yxx);
  float earth2 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xyx);
  float earth3 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xxy);
  float earth4 = SphereSDF(pos, earthRadius, earthPos - earthOffset.xyx);

  earth = sminCubic(earth, earth1, k_coeff);
  earth2 = sminCubic(earth2, earth3, k_coeff);

  earth = sminCubic(earth, earth2, k_coeff);
  earth = sminCubic(earth, earth4, k_coeff);

  float moon = SphereSDF(pos, moonRadius, moonPos);
  float crater1 = SphereSDF(pos, moonCraterRadius, moonPos + vec3(moonRadius / 2.0));
  moon = opSubtraction(crater1, moon);
	
  return min(moon, min(earth, min(c0, min(c1, c2))));
}

float ShadowSceneSDF(in vec3 pos, out int objHit) {
  float s0 = SphereSDF(pos, 0.5, l0);
  float s1 = SphereSDF(pos, 0.5, l1);
  float s2 = SphereSDF(pos, 0.5, l2);
  float s3 = SphereSDF(pos, 0.5, l3);
  float s4 = SphereSDF(pos, 0.5, l4);
  float s5 = SphereSDF(pos, 0.5, l5);

  float c0 = opSmoothIntersection(s0, s1, k_coeff);
  float c1 = opSmoothSubtraction(s2, s3, k_coeff);
  float c2 = sminCubic(s4, s5, k_coeff);

  float earth = SphereSDF(pos, earthRadius, earthPos - earthOffset.yxx);
  float earth1 = SphereSDF(pos, earthRadius, earthPos + earthOffset.yxx);
  float earth2 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xyx);
  float earth3 = SphereSDF(pos, earthRadius, earthPos + earthOffset.xxy);
  float earth4 = SphereSDF(pos, earthRadius, earthPos - earthOffset.xyx);

  earth = sminCubic(earth, earth1, k_coeff);
  earth2 = sminCubic(earth2, earth3, k_coeff);

  earth = sminCubic(earth, earth2, k_coeff);
  earth = sminCubic(earth, earth4, k_coeff);

  float moon = SphereSDF(pos, moonRadius, moonPos);
  float crater1 = SphereSDF(pos, moonCraterRadius, moonPos + vec3(moonRadius / 2.0));
  moon = opSubtraction(crater1, moon);
	
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
  if (earth < t) {
    t = earth;
    objHit = 4;
  }
  if (moon < t) {
    t = moon;
    objHit = 5;
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

float RayMarchShadow(in vec3 eye, in vec3 viewRayDirection, out int objHit) {
  float marchedDist = 0.0;
  float minDist = 0.0;
  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
      minDist = ShadowSceneSDF(eye + marchedDist * viewRayDirection, objHit);
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

float StarsRayMarch(in vec3 eye, in vec3 viewRayDirection) {
  float marchedDist = 0.0;
  float minDist = 0.0;
  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
      minDist = -SphereSDF(eye + marchedDist * viewRayDirection, 100.0, vec3(0.0, 0.0, 0.0));
      if (minDist < EPSILON) {
          // We're inside the scene surface!
          return marchedDist;
      }
      // Move along the view ray
      marchedDist += minDist;
  }
  return -1.0;
}

bool ShadowTest(vec3 p, vec3 lightPos) {

  bool returnVal = false;

  vec3 rayDirection = normalize(lightPos - p);
  float lengthBetweenPointAndLight = length(lightPos - p);

  vec3 shadowRayOrigin = p + rayDirection;
  vec3 shadowRayDirection = rayDirection;

  int objHit = -1;
  float t = -1.0;
  t = RayMarchShadow(shadowRayOrigin, shadowRayDirection, objHit);

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
    color = vec3(0.0, 1.0, 0.0);
  }
  else if (objHit == 2) {
    color = vec3(0.0, 0.0, 1.0);
  }
  else if (objHit == 3) {
    p = rotateX(p, u_Time * .00314159);
    float weight = random1o3i(p);
    return mix(vec3(1.0, 167.0/255.0, 0.0), vec3(1.0, 77.0/255.0, 0.0), weight);
  }
  else if (objHit == 4) {
    color = vec3(0.0, 119.0/255.0, 190.0/255.0);
  }
  else if (objHit == 5) {
    color = vec3(81.0/255.0, 84.0/255.0, 87.0/255.0);
  }
  else {
    return vec3(0.0, 0.0, 0.0);
  }

  vec3 sumLightColors = vec3(0.0);

  float ambientTerm = 0.2;

  vec3 sunPosTmp = sunPos;
  vec2 offset = vec2(0.0, sunRadius / 2.0);

  vec3 lights[6] = vec3[6](vec3(sunPos + offset.yxx), vec3(sunPos - offset.yxx),
                           vec3(sunPos + offset.xyx), vec3(sunPos - offset.xyx),
                           vec3(sunPos + offset.xxy), vec3(sunPos - offset.xxy));

  for (int i = 0; i < 6; i++) {
    sunPosTmp = lights[i];
    if(!ShadowTest(p, sunPosTmp)) {
      vec3 lightVec = normalize(sunPos - p);

      // Calculate the diffuse term for Lambert shading
      float diffuseTerm = clamp(dot(n, lightVec), 0.0, 1.0);    // Avoid negative lighting values with clamp

      float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                          //to simulate ambient lighting. This ensures that faces that are not
                                                          //lit by our point light are not completely black.

      sumLightColors += sunHueAndIntensity * lightIntensity;
    }
  }
  sumLightColors /= 6.0;

  sumLightColors = clamp(sumLightColors, ambientTerm, 10.0);

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

vec3 StarsIntersection(in vec3 eye, in vec3 viewRayDirection) {
  float t = -1.0;
  t = StarsRayMarch(eye, viewRayDirection);

  vec3 intersectPoint = eye + t * viewRayDirection;
  return intersectPoint;
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

  // earthPos = rotateY(earthPos, rotation);
  // earthPos.y = earthPos.y + cos(rotation);

  // moonPos = rotateY(moonPos, rotation1);
  // moonPos.y = moonPos.y + cos(rotation1);
  // moonPos += earthPos;


  vec3 rayOrigin;
  vec3 rayDirection;
  RayCast(rayOrigin, rayDirection, 45.f);

  Intersection intersection = SceneIntersection(rayOrigin, rayDirection);

  if (intersection.objHit != -1) {
    out_Col = vec4(ComputeColor(intersection.p, intersection.normal, intersection.objHit), 1.0);
  }
  else {

    float randomFract = random1o2i(fs_Pos) * 100.0;

    if (randomFract < 0.1) {
      out_Col = vec4(1.0, 1.0, 1.0, 1.0);
    }
    else {
      out_Col = vec4(0.0, 0.0, 0.0, 1.0);
    }

    // vec3 point = StarsIntersection(rayOrigin, rayDirection);

    // float a = fract(point.x);
    // if (a > 0.7 && a < 0.8) {
    //   float b = fract(point.y);
    //   if (b > 0.2 && b < 0.3) {
    //     float c = fract(point.z);
    //     if (c > 0.5 && c < 0.6) {
    //       c = ceil(c);
    //     }
    //     else {
    //       out_Col = vec4(0.0, 0.0, 0.0, 1.0);
    //     }
    //   }
    //   else {
    //   out_Col = vec4(0.0, 0.0, 0.0, 1.0);
    //   }
    // }
    // else{
    //   out_Col = vec4(0.0, 0.0, 0.0, 1.0);
    // }
    
    // //point = vec3(floor(point.x), floor(point.y), floor(point.z));
    // float randomFract = random1o3i(point) * 1000000.0;
    // // bool randomFract = (newPoint.x % 2 == 0) && (newPoint.x % 2 == 0) && (newPoint.x % 2 == 0);
    // //if (newPoint.y > 10.0) {
    // if (randomFract < 0.1) {
    //   out_Col = vec4(1.0, 1.0, 1.0, 1.0);
    // }
    // else {
    //   out_Col = vec4(0.0, 0.0, 0.0, 1.0);
    // }
  }

}
