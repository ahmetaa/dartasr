library dartasr;

import 'dart:scalarlist';
import 'dart:math';
import 'frame_processor.dart';
import 'framedata.dart';
import '../math/float_lists.dart';

/**
 * Returns a Dither Frame Processor for normalized data. it adds or substracts normalized half bit's value to each
 * frame value.
 * @param sampleSizeInBits bits of the samples.
 * @return A Frame processor for dithering normalized samples.
 */
FrameProcessor ditherForNormalizedData(int sampleSizeInBits) {
  return new Dither(sampleSizeInBits, true);
}


/**
 * Returns a Dither Frame Processor for actual data. it adds or substracts half bit's value to each
 * sample value.
 *
 * @param sampleSizeInBits bits of the samples.
 * @return A Frame processor for dithering actual sample values.
 */
FrameProcessor dither(int sampleSizeInBits) {
    return new Dither(sampleSizeInBits, false);
}

/** Generates an instance of a Hamming window function. */
FrameProcessor hammingWindow(int length) {
    return new RaisedCosineWindow(0.46, length);
}

/** Generates an instance of a Hanning window function. */
FrameProcessor hanningWindow(int length) {
    return new RaisedCosineWindow(0.5, length);
}

/** Generates an instance of a Triangular window function. */
FrameProcessor triangularWindow(int length) {
    return new RaisedCosineWindow(0.0, length);
}

/**
 * Generates a Preemphasizer with optional [preemhasisFactor]. Preemhasis factor is generally between 0.9 and 1.0.
 * Default value is 0.97
 */
FrameProcessor preemphasizer([double preemhasisFactor]) {
    var preemp = ?preemhasisFactor ? 
        new Preemphasizer(preemhasisFactor) : new Preemphasizer(DEFAULT_PREEMPHASIS_FACTOR);    
}

/**
 * A Normalizer that converts signed integer values to double [-1.0 +1.0] range
 * @param bitRange input bit range. Such as 16 for 16 bit signed data.
 * @return a FrameProcessor for normalization
 */
FrameProcessor normalizer(int bitRange) {
    return new SampleNormalizer(bitRange);
}

/** Normalizer. Converts values from -1 to 1 values for given bit boundary. */
class SampleNormalizer implements FrameProcessor {
    double maxPositiveIntegerForSignedSample;

    SampleNormalizer(int bitCount) {
        this.maxPositiveIntegerForSignedSample = (0x7fffffff >> (32 - bitCount)).toDouble();
    }

    FrameData process(FrameData input) {
        if (input.size() == 0)
            return input;
        var data = input.data;
        for (int i = 0; i < data.length; i++) {
            data[i] = data[i] / maxPositiveIntegerForSignedSample;
        }
        return input;
    }
}

/**
 * Generates a Dither process which prevents abnormal value generation during FFT operation when values are all zero.
 * This is an in-place operation that alters values of the input FrameData.
 */
class Dither implements FrameProcessor {

    Float64List ditherLookup = new Float64List(512);
    final int MODULO = 511;

    Dither(int sampleSizeInBits, bool normalized) {
        Random r = new Random(0xBEEFCAFE); // we give a seed for same random sequence generation after each run
        for (int i = 0; i < ditherLookup.length; i++) {
            double val;
            if (normalized) {
                // val = random number between 0 and value of 1 bit for a normalized sample
                val = r.nextDouble() * (1.0 / (0x7fffffff >> (32 - sampleSizeInBits))) * 2;
            } else {
                val = r.nextDouble();
            }
            if (r.nextBool())
                val = -val;
            ditherLookup[i] = val;
        }
    }

    /** Applies In-Place dither to [input] */
     FrameData process(FrameData input) {
       for (int i = 0; i < input.data.length; i++) {
         input.data[i] += ditherLookup[i & MODULO];
       }
       return input;
    }
}

/**
 * A generic class for windowing algorithms. It pre-computes window sample weights for given
 * cosine parameter.
 */
class RaisedCosineWindow implements FrameProcessor {
    double alpha;
    Float64List cosineWindow;

    RaisedCosineWindow(double alpha, int length) {
        if (length <= 0)
            throw new IllegalArgumentException("Window length cannot be smaller than 1");
        this.alpha = alpha;
        cosineWindow = new Float64List(length);
        for (int i = 0; i < length; i++) {
            cosineWindow[i] = (1 - alpha) - alpha * cos(2 * PI * i / (length - 1.0));
        }
    }

    FrameData process(FrameData input) {
        Float64List d = input.copyOfData;
        multiplyToFirst(d, cosineWindow);
        return input.copy(d);
    }
}

/**
 * Implements a high-pass filter that compensates for attenuation in the audio data. Speech signals have an attenuation
 * (a decrease in intensity of a signal) of 20 dB/dec. It increases the relative magnitude of the higher frequencies
 * with respect to the lower frequencies.
 * <p/>
 * The Preemphasizer takes a [FrameData] object that usually represents audio data as input,
 * and outputs another FrameData with preemphasis applied. For each value X[i] in the input Data object X, the following formula is
 * applied to obtain the output Data object Y:
 * <p/>
 * <code> Y[i] = X[i] - (X[i-1] * preemphasisFactor) </code>
 * <p/>
 * where 'i' denotes time.
 * <p/>
 * The preemphasis factor has a value. A common value for this factor is something around 0.97.
 * The Preemphasizer emphasizes the high frequency components, because they usually contain much less energy than lower
 * frequency components, even though they are still important for speech recognition. It is a high-pass filter because
 * it allows the high frequency components to "pass through", while weakening or filtering out the low frequency
 * components.
 * <p/>
 * implementation and documentation is copied and slightly modified from Sphinx4 code. 
 */

final double DEFAULT_PREEMPHASIS_FACTOR = 0.97;

class Preemphasizer implements FrameProcessor {

    double preemphasisFactor;

    double prior;

    Preemphasizer(double preemphasisFactor) {
        this.preemphasisFactor = preemphasisFactor;
    }

    /** Applies pre-emphasis filter to the input Audio data. */
    void applyPreemphasis(Float64List input) {
        // set the prior value for the next Audio
        double nextPrior = prior;
        if (input.length > 0) {
            nextPrior = input[input.length - 1];
        }
        if (input.length > 1 && preemphasisFactor != 0.0) {
            // do preemphasis
            double current;
            double previous = input[0];
            input[0] = previous - preemphasisFactor * prior;
            for (int i = 1; i < input.length; i++) {
                current = input[i];
                input[i] = current - preemphasisFactor * previous;
                previous = current;
            }
        }
        prior = nextPrior;
    }

    /// in-place preemphasis.
    FrameData process(FrameData input) {
        applyPreemphasis(input.data);
        return input;
    }
}

