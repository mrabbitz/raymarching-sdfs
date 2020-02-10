import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, time: number, controls: Array<number>) {
    prog.setEyeRefUp(camera.controls.eye, camera.controls.center, camera.controls.up);
    prog.setTime(time);
    prog.Set_s_Radius(controls[0]);
    prog.Set_s_Intensity_R(controls[1]);
    prog.Set_s_Intensity_G(controls[2]);
    prog.Set_s_Intensity_B(controls[3]);
    prog.Set_e_Rotation_Speed(controls[4]);
    prog.Set_e_Dist_From_Sun(controls[5]);
    prog.Set_e_Radius(controls[6]);
    prog.Set_m_Rotation_Speed(controls[7]);
    prog.Set_m_Dist_From_Earth(controls[8]);
    prog.Set_m_Radius(controls[9]);
    prog.Set_m_Crater_Radius(controls[10]);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
