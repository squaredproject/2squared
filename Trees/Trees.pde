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

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

final static int FEET = 12;

Model model;
LX lx;

void setup() {
  size(800, 600, OPENGL);
  model = new Model();
  lx = new LX(this, model);
  lx.setPatterns(new LXPattern[] {
    new TestPattern(lx),
  }
  );

  lx.ui.addLayer(new UICameraLayer(lx.ui)
    .setRadius(240)
    .setCenter(model.cx, model.cy, model.cz)
    .addComponent(new UIPointCloud(lx).setPointWeight(2))
    .addComponent(new UICubes())
    );
  lx.ui.addLayer(new UIPatternDeck(lx.ui, lx, 4, 4));

  try {
    lx.addOutput(
      new LXDatagramOutput(lx).addDatagram(
        new DDPSection(model.sections.get(0)).setAddress(InetAddress.getByName("10.0.0.100"))
      )
    );
  } catch (Exception x) {
    println(x);
  }
}
  
void draw() {
  background(#222222);
}

class UICubes extends UICameraComponent {
  
  protected void onDraw(UI ui) {
    lights();
    directionalLight(0, 10, 50, 1, -2, 1);
    directionalLight(120, 10, 50, -1, -2, 1);
    
    noStroke();
    fill(#333333);
    box(20*FEET, 1, 20*FEET);
    
    color[] colors = lx.getColors();
    
    noStroke();    
    for (Cube cube : model.cubes) {
      pushMatrix();
      fill(colors[cube.points.get(0).index]);
      translate(cube.cx, cube.cy, cube.cz);
      rotateY(-cube.ry * PI / 180);
      rotateX(-cube.rx * PI / 180);
      rotateZ(-cube.rz * PI / 180);
      box(cube.size, cube.size, cube.size);
      popMatrix();
    }

    noLights();
  }
}

