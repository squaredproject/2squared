DDPDatagram clusterDatagram(Cluster cluster) {
  int[] pointIndices = new int[cluster.points.size()];
  int pi = 0;
  for (LXPoint p : cluster.points) {
    pointIndices[pi++] = p.index;
  }
  return new DDPDatagram(pointIndices);
}

