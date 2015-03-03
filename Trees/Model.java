import java.awt.geom.Point2D;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.google.gson.JsonObject;

import heronarts.lx.LX;
import heronarts.lx.LXLayer;
import heronarts.lx.LXLoopTask;
import heronarts.lx.effect.LXEffect;
import heronarts.lx.model.LXAbstractFixture;
import heronarts.lx.model.LXModel;
import heronarts.lx.model.LXPoint;
import heronarts.lx.transform.LXTransform;

import toxi.geom.Vec2D;
import toxi.geom.Vec3D;
import toxi.math.MathUtils;

class Geometry {

  final static int INCHES = 1;
  final static int FEET = 12 * INCHES;

  /**
   * This defines the positions of the trees, which are
   * x (left to right), z (front to back), and rotation
   * in degrees.
   */
  final static float[][] TREE_POSITIONS = {
    /*  X-pos    Y-pos    Rot  */
    {  15*Geometry.FEET,  15*Geometry.FEET,   0  }
  };

  final static int FRONT = 0;
  final static int RIGHT = 1;
  final static int REAR = 2;
  final static int LEFT = 3;
  final static int FRONT_RIGHT = 4;
  final static int REAR_RIGHT = 5;
  final static int REAR_LEFT = 6;
  final static int FRONT_LEFT = 7;

  final static float CORNER_RADIUS = 62 * FEET;
  final static float CORNER_DISTANCE = 786;

  /**
   * Height of the trees.
   */
  public final static float HEIGHT = 570;  
  
  /**
   * Radius of the curved arches
   */
  public final static float MIDDLE_RADIUS = 85 * FEET;
  
  /**
   * Distance from the center of the tree to the center
   * point of the curve radials.
   */
  public final static float MIDDLE_DISTANCE = 1050; 
  
  /**
   * Height of the center point of the radial curve
   */
  public final static float VERTICAL_MIDPOINT = 156;
 
  /**
   * Spacing between horizontal cross-beams
   */
  public final static float BEAM_SPACING = 42;
  
  /**
   * Number of cross-beams
   */
  public final static int NUM_BEAMS = 11;
  
  /**
   * Width of cross-beam inches
   */
  public final static float BEAM_WIDTH = 6;

  
  /**
   * The heights of each cross-support on the arched beams
   */
  public final float[] heights;
  
  /**
   * At each cross-support point, the distance the support
   * is from the center of the tree.
   */
  public final float[] distances;

  Geometry() {
    distances = new float[(int) (HEIGHT/BEAM_SPACING + 2)];
    heights = new float[(int) (HEIGHT/BEAM_SPACING + 2)];
    for (int i = 0; i < heights.length; ++i) {
      heights[i] = Math.min(HEIGHT, i * BEAM_SPACING);
      distances[i] = distanceFromCenter(heights[i]);
    }
  }
  
  float distanceFromCenter(float atHeight) {
    float oppositeLeg = VERTICAL_MIDPOINT - atHeight;
    double angle = Math.asin(oppositeLeg / MIDDLE_RADIUS);
    float adjacentLeg = MIDDLE_RADIUS * (float)Math.cos(angle);
    return MIDDLE_DISTANCE - adjacentLeg;  
  }
  
  float angleFromAxis(float atHeight) {
    // This is some shitty trig. I am sure there
    // is a simpler way but it wasn't occuring to me.
    float x1 = MIDDLE_DISTANCE - distanceFromCenter(atHeight);
    double a1 = Math.acos(x1 / MIDDLE_RADIUS); 
    
    float r = MIDDLE_RADIUS;
    float y = Cluster.BRACE_LENGTH / 2;
    double a = Math.asin(y/r);
    double a2 = a1 - 2*a;
    
    double x2 = Math.cos(a2) * MIDDLE_RADIUS;
    
    return (float)Math.asin((x2-x1) /Cluster.BRACE_LENGTH); 
  }
}

class Model extends LXModel {
  
  /**
   * Trees in the model
   */
  public final List<Tree> trees;
  
  /**
   * Clusters in the model
   */
  public final List<Cluster> clusters;
  
  /**
   * Lookup table from cluster UID to cluster object.
   */
  public final Map<String, Cluster> clustersByIp;
  
  /**
   * Cubes in the model
   */
  public final List<Cube> cubes;

  private final ArrayList<ModelTransform> modelTransforms = new ArrayList<ModelTransform>();
    
  Model(Geometry geometry, List<TreeConfig> clusterConfig) {
    super(new Fixture(geometry, clusterConfig));
    Fixture f = (Fixture) this.fixtures.get(0);
    this.trees = Collections.unmodifiableList(f.trees);
    
    List<Cluster> _clusters = new ArrayList<Cluster>();
    Map<String, Cluster> _clustersByIp = new HashMap<String, Cluster>();
    for (Tree tree : this.trees) {
      for (Cluster cluster : tree.clusters) {
        _clusters.add(cluster);
        _clustersByIp.put(cluster.ipAddress, cluster);
      }
    }
    this.clusters = Collections.unmodifiableList(_clusters);
    this.clustersByIp = Collections.unmodifiableMap(_clustersByIp);
    
    List<Cube> _cubes = new ArrayList<Cube>();
    for (Cluster cluster : this.clusters) {
      for (Cube cube : cluster.cubes) {
        _cubes.add(cube);
      }
    }
    this.cubes = Collections.unmodifiableList(_cubes);
  }
  
  private static class Fixture extends LXAbstractFixture {
    
    final List<Tree> trees = new ArrayList<Tree>();
    
    private Fixture(Geometry geometry, List<TreeConfig> clusterConfig) {
      int treeIndex = 0;
      for (float[] treePosition : Geometry.TREE_POSITIONS) {
        trees.add(new Tree(geometry, clusterConfig, treeIndex++, treePosition[0], treePosition[1], treePosition[2]));
      }
      for (Tree tree : trees) {
        for (LXPoint p : tree.points) {
          points.add(p);
        }
      }
    }
  }

  public void addModelTransform(ModelTransform modelTransform) {
    modelTransforms.add(modelTransform);
  }

  public void runTransforms() {
    for (Cube cube : cubes) {
      cube.resetTransform();
    }
    for (ModelTransform modelTransform : modelTransforms) {
      modelTransform.transform(this);
    }
    for (Cube cube : cubes) {
      cube.didTransform();
    }
  }
}

class TreeConfig {
  int treeIndex;
  String ipAddress;
  int face;
  int level;
  float offset;
  float mountPoint;
  float skew;
}

class Tree extends LXModel {
  
  /**
   * Clusters in the tree
   */
  public final List<Cluster> clusters;
  
  /**
   * Cubes in the tree
   */
  public final List<Cube> cubes;
  
  /**
   * index of the tree
   */
  public final int index;
  
  /**
   * x-position of center of base of tree
   */
  public final float x;
  
  /**
   * z-position of center of base of tree
   */
  public final float z;
  
  /**
   * Rotation in degrees of tree about vertical y-axis
   */
  public final float ry;
  
  Tree(Geometry geometry, List<TreeConfig> clusterConfig, int treeIndex, float x, float z, float ry) {
    super(new Fixture(geometry, clusterConfig, treeIndex, x, z, ry));
    Fixture f = (Fixture)this.fixtures.get(0);
    this.index = treeIndex;
    this.clusters = Collections.unmodifiableList(f.clusters);
    List<Cube> _cubes = new ArrayList<Cube>();
    for (Cluster cluster : clusters) {
      for (Cube cube : cluster.cubes) {
        _cubes.add(cube);
      }
    }
    this.cubes = Collections.unmodifiableList(_cubes);
    this.x = x;
    this.z = z;
    this.ry = ry;
  }
  
  private static class Fixture extends LXAbstractFixture {
    
    final List<Cluster> clusters = new ArrayList<Cluster>();
    
    Fixture(Geometry geometry, List<TreeConfig> clusterConfig, int treeIndex, float x, float z, float ry) {
      Vec3D treeCenter = new Vec3D(x, 0, z);
      LXTransform t = new LXTransform();
      t.translate(x, 0, z);
      t.rotateY(ry * MathUtils.PI / 180);
      
      for (TreeConfig cp : clusterConfig) {
        if (cp.treeIndex == treeIndex) {
          String ipAddress = cp.ipAddress;
          int clusterLevel = cp.level;
          int clusterFace = cp.face;
          float clusterOffset = cp.offset;
          float clusterMountPoint = cp.mountPoint;
          float clusterSkew = cp.skew;
          
          t.push();
          float cry = 0;
          switch (clusterFace) {
            // Could be math, but this way it's readable!
            case Geometry.FRONT: case Geometry.FRONT_RIGHT:                  break;
            case Geometry.RIGHT: case Geometry.REAR_RIGHT:  cry = MathUtils.HALF_PI;   break;
            case Geometry.REAR:  case Geometry.REAR_LEFT:   cry = MathUtils.PI;        break;
            case Geometry.LEFT:  case Geometry.FRONT_LEFT:  cry = MathUtils.THREE_HALVES_PI; break;
          }
          switch (clusterFace) {
            case Geometry.FRONT_RIGHT:
            case Geometry.REAR_RIGHT:
            case Geometry.REAR_LEFT:
            case Geometry.FRONT_LEFT:
              clusterOffset = 0;
              break;
          }
          t.rotateY(cry);
          t.translate(clusterOffset * geometry.distances[clusterLevel], geometry.heights[clusterLevel] + clusterMountPoint, -geometry.distances[clusterLevel]);
          
          switch (clusterFace) {
            case Geometry.FRONT_RIGHT:
            case Geometry.REAR_RIGHT:
            case Geometry.REAR_LEFT:
            case Geometry.FRONT_LEFT:
              t.translate(geometry.distances[clusterLevel], 0, 0);
              t.rotateY(MathUtils.QUARTER_PI);
              cry += MathUtils.QUARTER_PI;
              break;
          }
          clusters.add(new Cluster(ipAddress, treeCenter, t, ry + cry*180/MathUtils.PI, 180/MathUtils.PI*geometry.angleFromAxis(t.y()), clusterSkew));
          t.pop();
        }
      }

      for (Cluster cluster : this.clusters) {
        for (LXPoint p : cluster.points) {
          this.points.add(p);
        }
      }
    }
  }
}

class Cluster extends LXModel {
  
  /**
   * Length of the metal brace on the back of the cluster
   */
  public final static float BRACE_LENGTH = 62;
  
  /**
   * Number of large 12-LED cubes in cluster
   */
  public final static int LARGE_CUBES_PER_CLUSTER = 3;
  
  /**
   * Number of smaller 6-LED cubes in cluster
   */
  public final static int SMALL_CUBES_PER_CLUSTER = 13;
  
  /**
   * Total number of LED pixels in cluster
   */
  public final static int PIXELS_PER_CLUSTER =
    LARGE_CUBES_PER_CLUSTER * Cube.PIXELS_PER_LARGE_CUBE +
    SMALL_CUBES_PER_CLUSTER * Cube.PIXELS_PER_SMALL_CUBE;
  
  /**
   * Cubes in the cluster
   */
  public final List<Cube> cubes;
  
  /**
   * Global x-position of cluster mount
   */
  public final float x;
  
  /**
   * Global y-position of cluster mount
   */
  public final float y;
  
  /**
   * Global z-position of cluster mount
   */
  public final float z;
  
  /**
   * x-position of cluster, relative to tree
   */
  public final float tx;
  
  /**
   * y-position of cluster, relative to tree
   */
  public final float ty;
  
  /**
   * z-position of cluster, relative to tree
   */
  public final float tz;
  
  /**
   * Rotation of cluster about vertical axis, in degrees relative to tree (not including tree rotation)
   */
  public final float ry;
  
  /**
   * Pitch of the cluster, in degrees (how much it tilts based on angle of supports
   */ 
  public final float rx;
  
  /**
   * Skew about the mount point.
   */
  public final float skew;
  
  /**
   * IP address of the cluster NDB
   */
  public final String ipAddress;
  
  Cluster(String ipAddress, Vec3D treeCenter, LXTransform transform, float ry, float rx, float skew) {
    super(new Fixture(treeCenter, transform, ry, rx, skew));
    Fixture f = (Fixture) this.fixtures.get(0);
    this.ipAddress = ipAddress;
    this.cubes = Collections.unmodifiableList(f.cubes);
    this.x = transform.x();
    this.y = transform.y();
    this.z = transform.z();
    this.tx = this.x - treeCenter.x;
    this.ty = this.y - treeCenter.y;
    this.tz = this.z - treeCenter.z;
    this.ry = ry;
    this.rx = rx;
    this.skew = skew;
  }
  
  private static class Fixture extends LXAbstractFixture {

    final List<Cube> cubes;
    
    Fixture(Vec3D treeCenter, LXTransform transform, float ry, float rx, float skew) {
      transform.push();
      transform.rotateX(rx * MathUtils.PI / 180);
      transform.rotateZ(skew * MathUtils.PI / 180);
      this.cubes = Arrays.asList(new Cube[] {
  // Cube(int clusterPosition, Vec2D treeCenter, LXTransform transform, float size, float x, float y, float z, float rx, float ry, float rz)
        new Cube( 1, treeCenter, transform, Cube.SMALL,    7, -98, -10,  185,  18, -18),
        new Cube( 2, treeCenter, transform, Cube.SMALL,    4, -87,  -9,  183,  20, -20),
        new Cube( 3, treeCenter, transform, Cube.SMALL,   -1, -78,  -8,  170,  30,   5),        
        new Cube( 4, treeCenter, transform, Cube.MEDIUM,   6, -70, -10,  183,  20,   0),        
        new Cube( 5, treeCenter, transform, Cube.MEDIUM,  -8, -65, -10,   0, -20,  -5),
        new Cube( 6, treeCenter, transform, Cube.GIANT,    6, -51,  -9,   0,  -5, -30),
        new Cube( 7, treeCenter, transform, Cube.SMALL,   -3,   1, -16, 190,   0,  20),
        new Cube( 8, treeCenter, transform, Cube.SMALL,   22, -44, -11,  185,   0,  15),
        new Cube( 9, treeCenter, transform, Cube.SMALL,   -8, -47, -13, 190,   0, -45),
        new Cube(10, treeCenter, transform, Cube.MEDIUM,  12, -33,  -8, 190,   0,   8),
        new Cube(11, treeCenter, transform, Cube.LARGE,   -4, -33,  -8,   0,  10, -15),
        new Cube(12, treeCenter, transform, Cube.SMALL,   18, -22,  -7, 190,   0,  45),        
        new Cube(13, treeCenter, transform, Cube.LARGE,    4, -16,  -9,   0,   0,  -5),
        new Cube(14, treeCenter, transform, Cube.MEDIUM, -12, -17,  -9,  175, -20,   0),
        new Cube(15, treeCenter, transform, Cube.SMALL,   -8,  -5,  -8,  185,  10, -45),
        new Cube(16, treeCenter, transform, Cube.SMALL,    3,  -2,  -7,  190, -10, -50),
      });
      for (Cube cube : this.cubes) {
        for (LXPoint p : cube.points) {
          this.points.add(p);
        }
      }
      transform.pop();
    }
  }
}

class Cube extends LXModel {

  public static final int PIXELS_PER_SMALL_CUBE = 6;
  public static final int PIXELS_PER_LARGE_CUBE = 12;
  
  public static final float SMALL = 8;
  public static final float MEDIUM = 12;
  public static final float LARGE = 16;
  public static final float GIANT = 17.5f;
  
  /**
   * Index of this cube in color buffer, colors[cube.index]
   */
  public final int index;
  
  /**
   * Index of this cube in cluster, from 1-16
   */
  public final int clusterPosition;
  
  /**
   * Size of this cube, one of SMALL/MEDIUM/LARGE/GIANT
   */
  public final float size;
  
  /**
   * Global x-position of center of cube
   */
  public final float x;
  
  /**
   * Global y-position of center of cube
   */
  public final float y;
  
  /**
   * Global z-position of center of cube
   */
  public final float z;
  
  /**
   * Pitch of cube, in degrees, relative to cluster
   */
  public final float rx;
  
  /**
   * Yaw of cube, in degrees, relative to cluster, after pitch
   */
  public final float ry;
  
  /**
   * Roll of cube, in degrees, relative to cluster, after pitch+yaw
   */
  public final float rz;
  
  /**
   * Local x-position of cube, relative to cluster 
   */
  public final float lx;
  
  /**
   * Local y-position of cube, relative to cluster 
   */
  public final float ly;
  
  /**
   * Local z-position of cube, relative to cluster 
   */
  public final float lz;
  
  /**
   * x-position of cube, relative to center of tree base 
   */
  public final float tx;
  
  /**
   * y-position of cube, relative to center of tree base 
   */
  public final float ty;
  
  /**
   * z-position of cube, relative to center of tree base 
   */
  public final float tz;
  
  /**
   * Radial distance from cube center to center of tree in x-z plane 
   */
  public final float r;
  
  /**
   * Angle in degrees from cube center to center of tree in x-z plane
   */
  public final float theta;
  
  /**
   * Point of the cube in the form (theta, y) relative to center of tree base
   */
  public final Vec2D cylinderPoint;

  public float transformedY;
  public float transformedTheta;
  public Vec2D transformedCylinderPoint;

  Cube(int clusterPosition, Vec3D treeCenter, LXTransform transform, float size, float x, float y, float z, float rx, float ry, float rz) {
    super(Arrays.asList(new LXPoint[] {
      new LXPoint(transform.x() + x, transform.y() + y, transform.z() + z)
    }));
    
    transform.push();
    transform.translate(x, y, z);
    transform.rotateX(rx);
    transform.rotateY(ry);
    transform.rotateZ(rz);
    
    this.index = this.points.get(0).index;
    this.clusterPosition = clusterPosition;
    this.size = size;
    this.rx = rx;
    this.ry = ry;
    this.rz = rz;
    this.lx = x;
    this.ly = y;
    this.lz = z;
    this.x = transform.x();
    this.y = transform.y();
    this.z = transform.z();
    this.tx = this.x - treeCenter.x;
    this.ty = this.y - treeCenter.y;
    this.tz = this.z - treeCenter.z;

    this.r = (float)Point2D.distance(treeCenter.x, treeCenter.z, this.x, this.z);
    this.theta = 180 + 180/MathUtils.PI*(float)Math.atan2(this.z - treeCenter.z, this.x - treeCenter.x);
    this.cylinderPoint = new Vec2D(this.theta, this.ty);
    
    transform.pop();
  }

  void resetTransform() {
    transformedTheta = theta;
    transformedY = y;
  }

  void didTransform() {
    transformedCylinderPoint = new Vec2D(transformedTheta, transformedY);
  }
}

abstract class Effect extends LXEffect {

  protected final Model model;

  Effect(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }
}

abstract class Layer extends LXLayer {

  protected final Model model;

  Layer(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }
}

abstract class ModelTransform extends Effect {
  ModelTransform(LX lx) {
    super(lx);

    model.addModelTransform(this);
  }

  public void run(double deltaMs) {}

  abstract void transform(Model model);
}

class ModelTransformTask implements LXLoopTask {

  protected final Model model;

  ModelTransformTask(Model model) {
    this.model = model;
  }

  public void loop(double deltaMs) {
    model.runTransforms();
  }
}

