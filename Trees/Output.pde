static class DDPCluster extends DDPDatagram {

  private final Cluster cluster;

  private static int[] clusterPointIndices(Cluster cluster) {
    int[] pointIndices = new int[Cluster.PIXELS_PER_CLUSTER];
    int i = 0;
    for (Cube cube : cluster.cubes) {
      for (LXPoint point : cube.points) {
        pointIndices[i++] = point.index;
      }
    }
    return pointIndices;
  }

  public DDPCluster(Cluster cluster) {
    super(clusterPointIndices(cluster));
    this.cluster = cluster;
  }
}

