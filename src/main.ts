import {vec2, vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  s_Radius: 2.0,
  s_Intensity_R: 2.0,
  s_Intensity_G: 2.0,
  s_Intensity_B: 2.0,
  e_Rotation_Speed: 10.0,
  e_Dist_From_Sun: 5.0,
  e_Radius: 0.5,
  m_Rotation_Speed: 5.0,
  m_Dist_From_Earth: 1.5,
  m_Radius: 0.3,
  m_Crater_Radius: 0.1
};

let square: Square;
let time: number = 0;

function loadScene() {
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  // time = 0;
}

function main() {
  window.addEventListener('keypress', function (e) {
    // console.log(e.key);
    switch(e.key) {
      // Use this if you wish
    }
  }, false);

  window.addEventListener('keyup', function (e) {
    switch(e.key) {
      // Use this if you wish
    }
  }, false);

  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI( { width: 300 } );

  var f1 = gui.addFolder('Sun');
  f1.add(controls, 's_Radius', 1.0, 10.0).step(1.0);
  f1.add(controls, 's_Intensity_R', 0.0, 4.0).step(0.25);
  f1.add(controls, 's_Intensity_G', 0.0, 4.0).step(0.25);
  f1.add(controls, 's_Intensity_B', 0.0, 4.0).step(0.25);

  var f2 = gui.addFolder('Earth');
  f2.add(controls, 'e_Rotation_Speed', -20.0, 20.0).step(1.0);
  f2.add(controls, 'e_Dist_From_Sun', 1.0, 20.0).step(0.5);
  f2.add(controls, 'e_Radius', 0.1, 1.5).step(0.1);

  var f3 = gui.addFolder('Moon');
  f3.add(controls, 'm_Rotation_Speed', -10.0, 10.0).step(1.0);
  f3.add(controls, 'm_Dist_From_Earth', 1.0, 5.0).step(0.5);
  f3.add(controls, 'm_Radius', 0.1, 1.0).step(0.1);
  f3.add(controls, 'm_Crater_Radius', 0.0, 1.0).step(0.05);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 10, -10), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(164.0 / 255.0, 233.0 / 255.0, 1.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  function processKeyPresses() {
    // Use this if you wish
  }

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    processKeyPresses();
    renderer.render(camera, flat, [
      square,
    ], time, [
      controls.s_Radius,
      controls.s_Intensity_R,
      controls.s_Intensity_G,
      controls.s_Intensity_B,
      controls.e_Rotation_Speed,
      controls.e_Dist_From_Sun,
      controls.e_Radius,
      controls.m_Rotation_Speed,
      controls.m_Dist_From_Earth,
      controls.m_Radius,
      controls.m_Crater_Radius
    ]);
    time++;
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
    flat.setDimensions(window.innerWidth, window.innerHeight);
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();
  flat.setDimensions(window.innerWidth, window.innerHeight);

  // Start the render loop
  tick();
}

main();
