library dartasr;

import 'dart:scalarlist';
import 'dart:math';
import '../frame_processor.dart';
import '../framedata.dart';

/**
 * Applies a logarithm and then a Discrete Cosine Transform (DCT) to the input data. The input data is normally the mel
 * spectrum. It has been proven that, for a sequence of real numbers, the discrete cosine transform is equivalent to the
 * discrete Fourier transform. Therefore, this class corresponds to the last stage of converting a signal to cepstra,
 * defined as the inverse Fourier transform of the logarithm of the Fourier transform of a signal. The property cepstrumSize
 * refers to the dimensionality of the coefficients that are actually returned, defaulting to
 * 13. When the input is mel-spectrum, the vector returned is the MFCC (Mel-Frequency Cepstral Coefficient) vector,
 * where the 0-th element is the energy value.
 * <p/>
 * Taken and simplified from Sphinx-4 front-end.
 */
class MelCepstrumProducer implements FrameProcessor {

     int cepstrumSize;

    int numberMelFilters;

    /// matrix containing shifted cosine values.
    List<Float64List> melcosine;

    MelCepstrumProducer(int cepstrumSize, int numberMelFilters) {
        this.cepstrumSize = cepstrumSize;
        this.numberMelFilters = numberMelFilters;
        melcosine = new List<Float64List>(cepstrumSize);
        for(int i =0; i<cepstrumSize; i++) {
          melcosine[i]= new Float64List(numberMelFilters);
        }
        computeMelCosine();
    }

    /** Process data, creating the mel cepstrum from an input mel spectrum frame. */
    FrameData process(FrameData input) {
        // we do not want to modify the input data values
        // because we will apply a logarithm on the values. So clone the input.
      Float64List melspectrum = applyLog(input.copyOfData);
      return input.copy(applyMelCosine(melspectrum));
    }

    Float64List applyLog(Float64List melspectrum) {
        if (melspectrum.length != numberMelFilters) {
            throw new ArgumentError ("MelSpectrum size is incorrect. length = ${melspectrum.length} numberMelFilters = ${numberMelFilters}");
        }
        // compute the log of the spectrum
        for (int i = 0; i < melspectrum.length; ++i) {
            if (melspectrum[i] > 0) {
                melspectrum[i] = log(melspectrum[i]);
            } else {
                // in case melspectrum[i] isn't greater than 0 instead of trying to compute a log we just
                // assign a very small number
                melspectrum[i] = -1.0e+5;
            }
        }
        return melspectrum;
    }

    /**
     * Compute the MelCosine filter bank.
     */
    void computeMelCosine() {
        double period =  (2 * numberMelFilters).toDouble();
        for (int i = 0; i < cepstrumSize; i++) {
            double frequency = (2 * PI * i / period).toDouble();
            for (int j = 0; j < numberMelFilters; j++) {
                melcosine[i][j] = cos(frequency * (j + 0.5));
            }
        }
    }

    /**
     * Apply the MelCosine filter to the given melspectrum.
     *
     * @param melspectrum the MelSpectrum data
     * @return MelCepstrum data produced by apply the MelCosine filter to the MelSpectrum data
     */
    Float64List applyMelCosine(Float64List melspectrum) {
        // create the cepstrum
        Float64List cepstrum = new Float64List(cepstrumSize);
        double beta = 0.5;
        // apply the melcosine filter
        for (int i = 0; i < cepstrum.length; i++) {
            Float64List melcosine_i = melcosine[i];
            int j = 0;
            cepstrum[i] += (beta * melspectrum[j] * melcosine_i[j]);
            for (j = 1; j < numberMelFilters; j++) {
                cepstrum[i] += (melspectrum[j] * melcosine_i[j]);
            }
            cepstrum[i] /= numberMelFilters;
        }

        return cepstrum;
    }
}

