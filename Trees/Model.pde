static class Model extends LXModel {
  
  final List<Tree> trees;
  final List<Section> sections;
  final List<Cube> cubes;
  
  Model() {
    super(new Fixture());
    Fixture f = (Fixture) this.fixtures.get(0);
    this.trees = Collections.unmodifiableList(f.trees);
    this.sections = Collections.unmodifiableList(f.sections);
    List<Cube> _cubes = new ArrayList<Cube>();
    for (Section section : this.sections) {
      for (Cube cube : section.cubes) {
        _cubes.add(cube);
      }
    }
    this.cubes = Collections.unmodifiableList(_cubes);
  }
  
  static class Fixture extends LXAbstractFixture {
    
    final List<Tree> trees = new ArrayList<Tree>();
    final List<Section> sections;
    
    Fixture() {
      this.sections = Arrays.asList(new Section[] {
        new Section(0, 0, 0, 0),
        new Section(30, 32, 10, 20),
      });
      for (Section section : this.sections) {
        for (LXPoint p : section.points) {
          this.points.add(p);
        }
      }
    }
  }
}

static class Tree extends LXModel {
  
  Tree(float x, float z, float ry) {
    super(new Fixture(x, z, ry));
  }
  
  static class Fixture extends LXAbstractFixture {
    Fixture(float x, float z, float ry) {
    }
  }
}

static class Section extends LXModel {
  
  final List<Cube> cubes;
  
  Section(float x, float y, float z, float ry) {
    super(new Fixture(x, y, z, ry));
    Fixture f = (Fixture) this.fixtures.get(0);
    this.cubes = Collections.unmodifiableList(f.cubes);
  }
  
  static class Fixture extends LXAbstractFixture {

    final List<Cube> cubes;
    
    Fixture(float x, float y, float z, float ry) {
      LXTransform transform = new LXTransform();
      transform.translate(x, y, z);
      transform.rotateY(ry * PI / 180);
      this.cubes = Arrays.asList(new Cube[] {
        new Cube(transform, Cube.GIANT, 0, 60, 0, 5, 10, 40),
        new Cube(transform, Cube.LARGE, -8, 75, -2, 15, 10, -5),
        new Cube(transform, Cube.LARGE, -9, 48, -2, 15, 10, -3),
        new Cube(transform, Cube.MEDIUM, -20, 56, -8, 20, -20, 0),
        new Cube(transform, Cube.MEDIUM, -14, 36, -6, 0, 15, -2),
        new Cube(transform, Cube.MEDIUM, 0, 38, -2, 14, 0, -15),
        new Cube(transform, Cube.SMALL, -14, 26, -6, 3, -15, 0),
        new Cube(transform, Cube.SMALL, -6, 22, 4, 10, -15, 0),
        new Cube(transform, Cube.SMALL, -6, 30, 0, 3, -15, 5),
        new Cube(transform, Cube.SMALL, -24, 42, 0, 0, 0, 20),
        new Cube(transform, Cube.SMALL, -20, 72, 0, 0, 0, 30),
        new Cube(transform, Cube.SMALL, 6, 46, 8, 0, 0, 20),
        new Cube(transform, Cube.MEDIUM, 8, 72, 8, 0, 0, 20),
        new Cube(transform, Cube.SMALL, -4, 86, -4, 10, 0, -5),
        new Cube(transform, Cube.SMALL, 2, 90, -4, -10, 0, -5),
        new Cube(transform, Cube.SMALL, 4, 82, -4, 0, 5, -10),
      });
      for (Cube cube : this.cubes) {
        for (LXPoint p : cube.points) {
          this.points.add(p);
        }
      }
    }
  }
}

static class Cube extends LXModel {
  
  static final int SMALL = 6;
  static final int MEDIUM = 9;
  static final int LARGE = 12;
  static final int GIANT = 14;
  
  final int size;
  final float rx, ry, rz;
  
  Cube(LXTransform transform, int size, float x, float y, float z, float rx, float ry, float rz) {
    super(new Fixture(transform, size, x, y, z, rx, ry, rz));
    this.size = size;
    this.rx = rx;
    this.ry = ry;
    this.rz = rz;
  }
  
  static class Fixture extends LXAbstractFixture {
    Fixture(LXTransform transform, int size, float x, float y, float z, float rx, float ry, float rz) {
      transform.push();
      transform.translate(x, y, z);
      transform.rotateY(ry * PI / 180);
      transform.rotateX(rx * PI / 180);
      transform.rotateZ(rz * PI / 180);
      
      transform.translate(0, size/2, 0);
      for (int i = 0; i < size; ++i) {
        this.points.add(new LXPoint(transform.x(), transform.y(), transform.z()));
        transform.translate(0, -1, 0);
      }

      transform.pop();
    }
  }
}
