class EQPattern extends TSPattern {

    final BasicParameter scale;
    final BasicParameter hue;
    final BasicParameter lowerFreq;
    final BasicParameter topFreq;

    
    GraphicEQ geq;

    EQPattern(LX lx) {
        super(lx);
        
        geq = new GraphicEQ(lx.audioInput());
        geq.start();

        addParameter(hue = new BasicParameter("Hue", 135, 0, 360));
        addParameter(scale = new BasicParameter("scale", .7, 1, 0));
        addParameter(lowerFreq = new BasicParameter("min", 0, 0, geq.numBands));
        addParameter(topFreq = new BasicParameter("max", 1, 1, geq.numBands));
    }

    public void run(double deltaMs) {
        if (getChannel().getFader().getNormalized() == 0) return;

        geq.loop(deltaMs);
        double d = geq.getAverage(int(lowerFreq.getValuef()),
                                  int(topFreq.getValuef() - lowerFreq.getValuef()));
        double scaled = (d / scale.getValue())*(lx.model.yMax - lx.model.yMin) + lx.model.yMin;
        for (Cube cube : model.cubes) {
            if (cube.transformedY < (scaled + 5))
                colors[cube.index] = LXColor.hsb(hue.getValue(), 100, 100);
            else
                colors[cube.index] = lx.hsb(0, 0, 0);
        }
    }
}

class LowEQ extends EQPattern {
    LowEQ(LX lx) {
        super(lx);
        hue.setValue(205);
        lowerFreq.setValue(0);
        topFreq.setValue(geq.numBands/3);
    }
}

class MidEQ extends EQPattern {
    MidEQ(LX lx) {
        super(lx);
        hue.setValue(43);
        lowerFreq.setValue(geq.numBands/3);
        topFreq.setValue(2*geq.numBands/3);
    }
}

class HighEQ extends EQPattern {
    HighEQ(LX lx) {
        super(lx);
        hue.setValue(0);
        lowerFreq.setValue(2*geq.numBands/3);
        topFreq.setValue(geq.numBands);
    }
}
