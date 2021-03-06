class HandController{

    float radius;

    PVector position = new PVector(0,0,0);
    color col;

    //coeff for scaling the position data
    float minX= -1;
    float maxX= 1;
    float minY= -1;
    float maxY=1;
    float minZ=0;
    float maxZ= 3;

    String state = "unknown";

    HandController(){

        radius=12;
    }


    void updateColor(KJoint joint){
         switch(joint.getState()) {
        case KinectPV2.HandState_Open:
            col= color(0,255,0);
            state= "open";
            break;
        case KinectPV2.HandState_Closed:
            col =color(255, 0, 0);
            state ="closed";
            break;
        case KinectPV2.HandState_Lasso:
            col = color(0, 0, 255);
            state="lasso";
            break;
        case KinectPV2.HandState_NotTracked:
            col= color(100, 100, 100);
            state="notTracked";
            break;
        }
    }

    void updatePosition(KJoint joint){
        //scale the position to the scene
        float xJoint = map(joint.getX(), minX,maxX, -sceneSize/2, sceneSize/2);
        float yJoint = map(joint.getY(), minY,maxY, -sceneSize/2, sceneSize/2);
        float zJoint = map(joint.getZ(), minZ,maxZ, -sceneSize/2, sceneSize/2);
        
        //rectification of y and z axis to be inverted
        position = new PVector(xJoint, -1*yJoint, -1*zJoint); 

    }




    void display(){
        stroke(col);
        fill(col);
        pushMatrix();
        translate(position.x, position.y, position.z);
        sphere(radius);
        popMatrix();
    }


    void displayPosition(){
        fill(255,128,0);
        String posX = nf(position.x,0,2);
        String posY = nf(position.y,0,2);
        String posZ = nf(position.z,0,2);
        text("X: "+posX + " // Y: " + posY+ " // Z: " + posZ + " // State: " + state, 0,0);

        //text("x: "+nf(position.x,2) + " // y:" + nf(position.y,2) + " // z: " + nf(position.z,2), 10, 15);
    }

    


}