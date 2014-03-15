DDPDatagram clusterDatagram(Cluster cluster) {
  int[] pointIndices = new int[Cluster.PIXELS_PER_CLUSTER];
  int pi = 0;
  for (Cube cube : cluster.cubes) {
    int numPixels = (cube.size >= Cube.LARGE) ? Cube.PIXELS_PER_LARGE_CUBE : Cube.PIXELS_PER_SMALL_CUBE;
    for (int i = 0; i < numPixels; ++i) {
      pointIndices[pi++] = cube.index;
    }
  }
  return new DDPDatagram(pointIndices);
}

