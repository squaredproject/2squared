#!/bin/sh
ln -s Model.pde ._Model.java
javadoc -classpath code/HeronLX.jar -d javadoc ._Model.java
rm ._Model.java

