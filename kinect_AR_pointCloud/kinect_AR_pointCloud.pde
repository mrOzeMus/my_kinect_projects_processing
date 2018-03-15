import processing.video.*;
import jp.nyatla.nyar4psg.*;
import java.nio.*;
import java.util.ArrayList;
import KinectPV2.KJoint;
import KinectPV2.*;

float angleIncrement=0;
float rx=0, ry=0, rz=0;
float[] scaleFactor = {100,100};
float[] translationFactor = { -55,-55};


//POINT CLOUD****************************************
int vertLoc;
//transformations
float a = 0;
int zval = 0;
float scaleVal = 300;
//value to scale the depth point when accessing each individual point in the PC.
float scaleDepthPoint = 300.0;
//Distance Threashold
int maxD = 1371; // 4m
int minD = 157; //  0m
//openGL object and shader
PGL pgl;
PShader sh;
//VBO buffer location in the GPU
int vertexVboId;
//****************************************

Capture cam;
MultiMarker nya;
float paramMouse1;
float paramMouse2;
PVector offset = new PVector(0, 0, 0);

KinectPV2 kinect;
PVector[] angleRotation={
new PVector(0, 0, 0), new PVector(0, 0, 0)};
PFont font;



void setup() {
  size(640, 480, P3D);
  colorMode(RGB, 100);
  font = createFont("FFScala", 32);
  println(MultiMarker.VERSION);

  cam = new Capture(this, 640, 480);
  nya = new MultiMarker(this, 640, 480, "data/camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
  nya.addARMarker("data/patt.hiro", 80);
  nya.addARMarker("data/patt.kanji", 80);
  nya.addNyIdMarker(0, 80); //id=2
  nya.addNyIdMarker(1, 80); //id=3
  cam.start();

  kinect = new KinectPV2(this);
  kinect.enableDepthMaskImg(true);
  kinect.enableSkeletonDepthMap(true);
  kinect.enableSkeleton3DMap(true);

  kinect.enableDepthImg(true);
  kinect.enablePointCloud(true);
  kinect.setLowThresholdPC(floor(minD));
  kinect.setHighThresholdPC(floor(maxD));
  kinect.init();

  //*************************
  sh = loadShader("frag.glsl", "vert.glsl");
  PGL pgl = beginPGL();
  IntBuffer intBuffer = IntBuffer.allocate(1);
  pgl.genBuffers(1, intBuffer);
  //memory location of the VBO
  vertexVboId = intBuffer.get(0);
  endPGL();
  //****************************
  skeletonInitValCol();
}



void draw() {

  /* Pour trouver manuellement valeur de profondeur
    minD=floor(map(mouseX,0,width, 0,500));
    maxD=floor(map(mouseY,0,height, minD,3000));
    println("minD: " + minD + " maxD: " + maxD);
   */
  //scaleDisplay = map(mouseX,0,width,0.1,4);
  //paramMouse2 = map(mouseY,0, height,-200,200);
  if (cam.available() != true) {
    return;
  }
  cam.read();
  nya.detect(cam);
  background(100, 100, 100);
  nya.drawBackground(cam);
  image(kinect.getDepthMaskImage(), 0, 0, 160, 120);
  for (int i = 0; i < 4; i++) {
    //************ici réglage pour chaque apparition
    //rotateY(i*PI);
    //**************
    if ((!nya.isExist(i))) {
      return;
    }
    skeletonArray = new ArrayList();
    skeletonArray = kinect.getSkeletonDepthMap();
    getDataSkeleton();
    //nya.setARPerspective();

    pushMatrix();
    nya.beginTransform(i);

    //translate(0,0,-40);
    //***draw scene, axis, floor
      fill(100, 100, 100);
   //   rect(-40, -40, 80, 80);

      stroke(0);
      strokeWeight(2);
      line(0, 0, 0, 100, 0, 0);
      textFont(font, 20.0);
      text("X", 100, 0, 0);
      line(0, 0, 0, 0, 100, 0);
      textFont(font, 20.0);
      text("Y", 0, 100, 0);
      line(0, 0, 0, 0, 0, 100);
      textFont(font, 20.0);
      text("Z", 0, 0, 100);
    //****Inital rotation for having right axis order
    rotateX(HALF_PI);
    rotateY(ry);
    rotateZ(rz);
    //**************
    //custom rotation--------
    rotateX(angleRotation[i].x);
    rotateY(angleRotation[i].y);
    rotateZ(angleRotation[i].z);
    //---------------
    drawBody();
    //*****************************
    drawPointCloud(i);
    //*****************************
    nya.endTransform();
    popMatrix();
  }
  angleIncrement+= 0.1;
}




void drawPointCloud(int i) {
  pushMatrix();
    
    rotateY(PI);
    translate(translationFactor[i], 0, translationFactor[i]);
    scale(scaleFactor[i]);
    // Threahold of the point Cloud.
    kinect.setLowThresholdPC(minD);
    kinect.setHighThresholdPC(maxD);
    //get the points in 3d space
    FloatBuffer pointCloudBuffer = kinect.getPointCloudDepthPos();
    /*Cette partie dessine en sphere l'emplacement de kinect
    stroke(0, 255, 0);
    for(int i = 0; i < kinect.WIDTHDepth * kinect.HEIGHTDepth; i+=30){
        float x = pointCloudBuffer.get(i*3 + 0) * scaleDepthPoint;
        float y = pointCloudBuffer.get(i*3 + 1) * scaleDepthPoint;
        float z = pointCloudBuffer.get(i*3 + 2) * scaleDepthPoint;
      // println(x);
        //strokeWeight(1);
        point(x, y, z);
    }
    */
    pgl = beginPGL();
    sh.bind();
    vertLoc = pgl.getAttribLocation(sh.glProgram, "vertex");
    pgl.enableVertexAttribArray(vertLoc);
    int vertData = kinect.WIDTHDepth * kinect.HEIGHTDepth * 3;
    {
      pgl.bindBuffer(PGL.ARRAY_BUFFER, vertexVboId);
      pgl.bufferData(PGL.ARRAY_BUFFER, Float.BYTES * vertData, pointCloudBuffer, PGL.DYNAMIC_DRAW);
      pgl.vertexAttribPointer(vertLoc, 3, PGL.FLOAT, false, Float.BYTES * 3, 0);
    }
    pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);
    pgl.drawArrays(PGL.POINTS, 0, vertData);
    pgl.disableVertexAttribArray(vertLoc);
    sh.unbind();
    endPGL();
  popMatrix();
}


void keyPressed(){

  
  if(keyCode ==129){ //touche 1
      scaleFactor[0] -=100;
      if(scaleFactor[0] < 0){ scaleFactor[0] = 1000;}
      scaleFactor[1] -=100;
      if(scaleFactor[1] < 0){ scaleFactor[1] = 1000;}
  }
  if(keyCode ==130){ // touche 2
      scaleFactor[0] +=100;
      if(scaleFactor[0] > 1000){ scaleFactor[0] = 100;}
      scaleFactor[1] +=100;
      if(scaleFactor[1] > 1000){ scaleFactor[1] = 100;}
  }

  if(keyCode ==132){ //touche 1
      translationFactor[0] -=30;
      if(translationFactor[0] < -500){ translationFactor[0] = 500;}
      translationFactor[1] -=30;
      if(translationFactor[1] < -500){ translationFactor[1] = 500;}
  }
  if(keyCode ==133){ // touche 2
      translationFactor[0] +=30;
      if(translationFactor[0] > 500){ translationFactor[0] = -500;}
      translationFactor[1] +=30;
      if(translationFactor[1] > 500){ translationFactor[1] = -500;}
  }


  println("scale: " + scaleFactor[0] + " , translation: " + translationFactor[0]);
  
}