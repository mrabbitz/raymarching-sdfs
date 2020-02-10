import {vec2, vec3, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;

  unifRef: WebGLUniformLocation;
  unifEye: WebGLUniformLocation;
  unifUp: WebGLUniformLocation;
  unifDimensions: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;

  s_Radius: WebGLUniformLocation;
  s_Intensity_R: WebGLUniformLocation;
  s_Intensity_G: WebGLUniformLocation;
  s_Intensity_B: WebGLUniformLocation;
  e_Rotation_Speed: WebGLUniformLocation;
  e_Dist_From_Sun: WebGLUniformLocation;
  e_Radius: WebGLUniformLocation;
  m_Rotation_Speed: WebGLUniformLocation;
  m_Dist_From_Earth: WebGLUniformLocation;
  m_Radius: WebGLUniformLocation;
  m_Crater_Radius: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.unifEye   = gl.getUniformLocation(this.prog, "u_Eye");
    this.unifRef   = gl.getUniformLocation(this.prog, "u_Ref");
    this.unifUp   = gl.getUniformLocation(this.prog, "u_Up");
    this.unifDimensions   = gl.getUniformLocation(this.prog, "u_Dimensions");
    this.unifTime   = gl.getUniformLocation(this.prog, "u_Time");

    this.s_Radius = gl.getUniformLocation(this.prog, "u_s_Radius");
    this.s_Intensity_R = gl.getUniformLocation(this.prog, "u_s_Intensity_R");
    this.s_Intensity_G = gl.getUniformLocation(this.prog, "u_s_Intensity_G");
    this.s_Intensity_B = gl.getUniformLocation(this.prog, "u_s_Intensity_B");
    this.e_Rotation_Speed = gl.getUniformLocation(this.prog, "u_e_Rotation_Speed");
    this.e_Dist_From_Sun = gl.getUniformLocation(this.prog, "u_e_Dist_From_Sun");
    this.e_Radius = gl.getUniformLocation(this.prog, "u_e_Radius");
    this.m_Rotation_Speed = gl.getUniformLocation(this.prog, "u_m_Rotation_Speed");
    this.m_Dist_From_Earth = gl.getUniformLocation(this.prog, "u_m_Dist_From_Earth");
    this.m_Radius = gl.getUniformLocation(this.prog, "u_m_Radius");
    this.m_Crater_Radius = gl.getUniformLocation(this.prog, "u_m_Crater_Radius");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  Set_s_Radius(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.s_Radius, t);
    }
  }
  Set_s_Intensity_R(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.s_Intensity_R, t);
    }
  }
  Set_s_Intensity_G(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.s_Intensity_G, t);
    }
  }
  Set_s_Intensity_B(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.s_Intensity_B, t);
    }
  }
  Set_e_Rotation_Speed(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.e_Rotation_Speed, t);
    }
  }
  Set_e_Dist_From_Sun(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.e_Dist_From_Sun, t);
    }
  }
  Set_e_Radius(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.e_Radius, t);
    }
  }
  Set_m_Rotation_Speed(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.m_Rotation_Speed, t);
    }
  }
  Set_m_Dist_From_Earth(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.m_Dist_From_Earth, t);
    }
  }
  Set_m_Radius(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.m_Radius, t);
    }
  }
  Set_m_Crater_Radius(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.m_Crater_Radius, t);
    }
  }

  setEyeRefUp(eye: vec3, ref: vec3, up: vec3) {
    this.use();
    if(this.unifEye !== -1) {
      gl.uniform3f(this.unifEye, eye[0], eye[1], eye[2]);
    }
    if(this.unifRef !== -1) {
      gl.uniform3f(this.unifRef, ref[0], ref[1], ref[2]);
    }
    if(this.unifUp !== -1) {
      gl.uniform3f(this.unifUp, up[0], up[1], up[2]);
    }
  }

  setDimensions(width: number, height: number) {
    this.use();
    if(this.unifDimensions !== -1) {
      gl.uniform2f(this.unifDimensions, width, height);
    }
  }

  setTime(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, t);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
  }
};

export default ShaderProgram;
