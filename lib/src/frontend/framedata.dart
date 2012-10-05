library dartasr;

import 'dart:scalarlist';

/**
 * This class represents a frame's data. It may carry arbitrary double values as data.
 * Each frame has a sequence and sample index value. To find the location of the frame in the source.
 */
class FrameData {

    Float64List _data;
    int sequenceId;
    int sampleIndex;

    FrameData EMPTY_FRAME = new FrameData([], -1, -1);

    FrameData(this._data, this.sequenceId, this.sampleIndex) {
        if (_data == null)
            throw new IllegalArgumentException("Data cannot be null!");
        this._data = data;
    }

    /**
     * Create a copy of this and replaces the data with [newData]
     */
    FrameData copy(Float64List newData) {
        return new FrameData(newData, sequenceId, sampleIndex);        
    }

    get size=> data.length;

    get data=> data;

    get copyOfData => data.clone();    

    String dataString() {
        StringBuffer sb = new StringBuffer();
        for (double v in data) {
            sb.add(v);
        }
        return sb.toString();
    }

}
