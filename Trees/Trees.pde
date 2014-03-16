import heronarts.lx.*;
import heronarts.lx.effect.*;
import heronarts.lx.model.*;
import heronarts.lx.output.*;
import heronarts.lx.parameter.*;
import heronarts.lx.pattern.*;
import heronarts.lx.transform.*;
import heronarts.lx.transition.*;
import heronarts.lx.modulator.*;
import heronarts.lx.ui.*;
import heronarts.lx.ui.control.*;

import ddf.minim.*;
import processing.opengl.*;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

final static int INCHES = 1;
final static int FEET = 12 * INCHES;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

static Geometry geometry = new Geometry();
Model model;
LX lx;
final BasicParameter bgLevel = new BasicParameter("BG", 25, 0, 50);

void setup() {
  size(960, 480, OPENGL);
  geometry = new Geometry();
  model = new Model();
  lx = new LX(this, model);
  lx.setPatterns(new LXPattern[] {
    new DoubleHelix(lx),
    new Twister(lx),
    new SparkleHelix(lx),
    new Stripes(lx),
    new SeeSaw(lx),
    new SweepPattern(lx),
    new ColoredLeaves(lx),
    new SyphonPattern(lx, this),
    new TestPattern(lx).setEligible(false),
    new TestCluster(lx).setEligible(false),
  });

  lx.ui.addLayer(new UICameraLayer(lx.ui)
    .setRadius(70*FEET)
    .setCenter(model.cx, 220, model.cz)
    .addComponent(new UITrees())
    );
  lx.ui.addLayer(new UIPatternDeck(lx.ui, lx, 4, 4));

  try {
    LXOutput output = new LXDatagramOutput(lx).addDatagram(
      clusterDatagram(model.clusters.get(0)).setAddress("10.0.0.105")
    );
    output.enabled.setValue(false);
    lx.addOutput(output);
  } catch (Exception x) {
    println(x);
  }
  
  lx.engine.framesPerSecond.setValue(60);
  
  // Enabling this breaks syphon support
  // lx.engine.setThreaded(true);
}
  
void draw() {
  background(#222222);
}

class UITrees extends UICameraComponent {
    
  protected void onDraw(UI ui) {
    lights();
    pointLight(0, 0, 80, model.cx, geometry.HEIGHT/2, -10*FEET);

    noStroke();
    fill(#191919);
    beginShape();
    vertex(0, 0, 0);
    vertex(105*FEET, 0, 0);
    vertex(105*FEET, 0, 30*FEET);
    vertex(0, 0, 30*FEET);
    endShape(CLOSE);

    drawTrees(ui);
    drawCubes(ui);
  }
  
  private void drawTrees(UI ui) {
    noStroke();
    fill(#333333);
    for (Tree tree : model.trees) {
      pushMatrix();
      translate(tree.x, 0, tree.z);
      rotateY(-tree.ry * PI / 180);
      drawTree(ui);
      popMatrix();
    }
  }
  
  private void drawTree(UI ui) {
    for (int i = 0; i < 4; ++i) {
      for (int y = 1; y < geometry.distances.length; ++y) {
        float beamY = geometry.heights[y];
        float prevY = geometry.heights[y-1];
        float distance = geometry.distances[y];
        float prevDistance = geometry.distances[y-1];
        
        if (y <= geometry.NUM_BEAMS) {
          beginShape();
          vertex(-distance, beamY - geometry.BEAM_WIDTH/2, -distance);
          vertex(-distance, beamY + geometry.BEAM_WIDTH/2, -distance);
          vertex(distance, beamY + geometry.BEAM_WIDTH/2, -distance);
          vertex(distance, beamY - geometry.BEAM_WIDTH/2, -distance);
          endShape(CLOSE);
        }
        
        beginShape();
        vertex(-geometry.BEAM_WIDTH/2, prevY, -prevDistance);
        vertex(geometry.BEAM_WIDTH/2, prevY, -prevDistance);
        vertex(geometry.BEAM_WIDTH/2, beamY, -distance);
        vertex(-geometry.BEAM_WIDTH/2, beamY, -distance);
        endShape(CLOSE);
        
        beginShape();
        vertex(prevDistance-geometry.BEAM_WIDTH/2, prevY, -prevDistance-geometry.BEAM_WIDTH/2);
        vertex(prevDistance+geometry.BEAM_WIDTH/2, prevY, -prevDistance+geometry.BEAM_WIDTH/2);
        vertex(distance+geometry.BEAM_WIDTH/2, beamY, -distance+geometry.BEAM_WIDTH/2);
        vertex(distance-geometry.BEAM_WIDTH/2, beamY, -distance-geometry.BEAM_WIDTH/2);
        endShape(CLOSE);        
      }
      rotateY(PI/2); 
    }    
  }
     
  private void drawCubes(UI ui) {
    
    color[] colors = lx.getColors();
    noStroke();    
    noFill();
    
//    beginShape(POINTS);
//    for (Cube cube : model.cubes) {
//      stroke(colors[cube.points.get(0).index]);
//      strokeWeight(cube.size*2);
//      vertex(cube.x, cube.y, cube.z);
//    }
//    endShape();
 
    
    for (Cube cube : model.cubes) {
      pushMatrix();
      fill(colors[cube.index]);
      translate(cube.x, cube.y, cube.z);
      rotateY(-cube.ry * PI / 180);
      rotateX(-cube.rx * PI / 180);
      rotateZ(-cube.rz * PI / 180);
      box(cube.size, cube.size, cube.size);
      popMatrix();
    }

    noLights();
  }
}
