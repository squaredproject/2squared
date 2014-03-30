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
import rwmidi.*;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

final static int INCHES = 1;
final static int FEET = 12 * INCHES;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

final static int A = 0;
final static int B = 1;

final static float CHAIN = -12;
final static float BOLT = 22;

final static int FRONT = 0;
final static int RIGHT = 1;
final static int REAR = 2;
final static int LEFT = 3;
final static int FRONT_RIGHT = 4;
final static int REAR_RIGHT = 5;
final static int REAR_LEFT = 6;
final static int FRONT_LEFT = 7;

static Geometry geometry = new Geometry();
Model model;
LX lx;
LXDatagramOutput output;
LXDatagram datagram;
UIMultiDeck uiDeck;
MidiEngine midiEngine;
final BasicParameter bgLevel = new BasicParameter("BG", 25, 0, 50);
final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);  

LXPattern[] patterns(LX lx) {
  LXPattern[] patterns = new LXPattern[] {
    new Twister(lx),
    new MarkLottor(lx),
    new DoubleHelix(lx),
    new SparkleHelix(lx),
    new Lightning(lx),
    new SparkleTakeOver(lx),
    new MultiSine(lx),
    new Ripple(lx),
    new SeeSaw(lx),
    new SweepPattern(lx),
    new ColoredLeaves(lx),
    new Stripes(lx),
    new SyphonPattern(lx, this),
    new TestPattern(lx).setEligible(false),
    new TestCluster(lx).setEligible(false),
    new Pulley(lx),
    new Springs(lx),
    new Lattice(lx),
  };
  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  for (LXPattern p : patterns) {
    p.setTransition(t);
  }
  return patterns;
}

void setup() {
  size(960, 600, OPENGL);
  geometry = new Geometry();
  model = new Model();
  lx = new LX(this, model);
  lx.setPatterns(patterns(lx));
  for (int i = 1; i < 8; ++i) {
    lx.engine.addDeck(patterns(lx));
  }
  for (LXDeck deck : lx.engine.getDecks()) {
    deck.goIndex(deck.index);
    deck.setFaderTransition(new BlendTransition(lx, ADD, BlendTransition.Mode.HALF));
  }

  try {
    output = new LXDatagramOutput(lx).addDatagram(
      datagram = clusterDatagram(model.clusters.get(0)).setAddress("10.0.0.105")
    );
    output.enabled.setValue(false);
    lx.addOutput(output);
  } catch (Exception x) {
    println(x);
  }
  
  lx.ui.addLayer(new UICameraLayer(lx.ui) {
      protected void beforeDraw() {
        hint(ENABLE_DEPTH_TEST);
        pushMatrix();
        translate(0, 6*FEET, 0);
      }
      protected void afterDraw() {
        popMatrix();
        hint(DISABLE_DEPTH_TEST);
      }  
    }
    .setRadius(90*FEET)
    .setCenter(model.cx, model.cy, model.cz)
    .addComponent(new UITrees())
    );
  lx.ui.addLayer(new UIChannelFaders(lx.ui));
  lx.ui.addLayer(uiDeck = new UIMultiDeck(lx.ui));
  lx.ui.addLayer(new UIOutput(lx.ui, width-144, 4));
  
  midiEngine = new MidiEngine();
  
  lx.engine.framesPerSecond.setValue(60);  
  lx.engine.setThreaded(true);
}
  
void draw() {
  background(#222222);
}

class UITrees extends UICameraComponent {
  
  color[] previewBuffer;
  
  UITrees() {
    previewBuffer = new int[lx.total];
  }
  
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
    
    color[] colors;
    if (previewChannel.getValuei() >= 8) {
      colors = lx.getColors();
    } else {
      lx.engine.getDeck(previewChannel.getValuei()).copyBuffer(colors = previewBuffer);
    }
    noStroke();    
    noFill();
    
    for (Tree tree : model.trees) {
      for (Cluster cluster : tree.clusters) {
        pushMatrix();
        translate(cluster.x, cluster.y, cluster.z);
        rotateY(-cluster.ry * PI / 180);
        rotateX(-cluster.rx * PI / 180);
        for (Cube cube : cluster.cubes) {
          pushMatrix();
          fill(colors[cube.index]);
          translate(cube.lx, cube.ly, cube.lz);
          rotateY(-cube.ry * PI / 180);
          rotateX(-cube.rx * PI / 180);
          rotateZ(-cube.rz * PI / 180);
          box(cube.size, cube.size, cube.size);
          popMatrix();
        }
        popMatrix();
      }
    }

    noLights();
  }
}

class UIOutput extends UIWindow {
  UIOutput(UI ui, float x, float y) {
    super(ui, "LIVE OUTPUT", x, y, 140, 72);
    float yPos = UIWindow.TITLE_LABEL_HEIGHT;
    new UIButton(4, yPos, width-8, 20)
      .setParameter(output.enabled)
      .setLabel(datagram.getAddress().toString())
      .addToContainer(this);
    yPos += 24;
    new UISlider(4, yPos, width-8, 20)
    .setParameter(output.brightness)
    .addToContainer(this);
  }
}

