library dartasr;

import 'dart:math';
import '../frame_processor.dart';
import '../framedata.dart';
import '../../math/float_lists.dart';

/**
 * reduced, modified and converted to Dart from LomontFFT code (www.lomont.org).
 * Original LomontFFT code's copyright notice is below:
 * Copyright Chris Lomont 2010-2012.
 * This code and any ports are free for all to use for any reason as long as this header is left in place.
 * Version 1.1, Sept 2011
 */
class SpectralEnergyCalculator implements FrameProcessor {

    int size;
    /**
     * Pre-computed sine/cosine tables for speed
     */
    List<double> cosTable;
    List<double> sinTable;

    SpectralEnergyCalculator(this.size) {
        if ((size & (size - 1)) != 0)
            throw new IllegalArgumentException("data length $size in FFT is not a power of 2");
        cosTable = new List<double>(size);
        sinTable = new List<double>(size);
        _initialize();
    }

    /**
     * Compute the forward Fourier Transform of data, with data containing complex valued data as alternating real and
     * imaginary parts. The length must be a power of 2. This method caches values and should be slightly faster on
     * than the FFT method for repeated uses. It is also slightly more accurate. Data is transformed in place.
     *
     * @param data The complex data stored as alternating real and imaginary parts
     */
    void tableFFT(List<double> data) {
        int n = size ~/ 2;    // n is the number of samples
        reverse(data, n); // bit index data reversal
        int mmax = 1;
        int tptr = 0;
        while (n > mmax) {
            int istep = 2 * mmax;
            for (int m = 0; m < istep; m += 2) {
                double wr = cosTable[tptr];
                double wi = sinTable[tptr++];
                for (int k = m; k < 2 * n; k += 2 * istep) {
                    int j = k + istep;
                    double tempr = wr * data[j] - wi * data[j + 1];
                    double tempi = wi * data[j] + wr * data[j + 1];
                    data[j] = data[k] - tempr;
                    data[j + 1] = data[k + 1] - tempi;
                    data[k] = data[k] + tempr;
                    data[k + 1] = data[k + 1] + tempi;
                }
            }
            mmax = istep;
        }
    }

    /**
     * Compute the forward Fourier Transform of data, with data containing real valued data only.
     * The output is complex valued after the first two entries, stored in alternating real and imaginary parts.
     * The first two returned entries are the real parts of the first and last value from the conjugate symmetric output,
     * which are necessarily real. The length must be a power. If data size is smaller than the FFT size
     * zero padding is applied.
     *
     * @param data The complex data stored as alternating real and imaginary parts
     * @throws IllegalArgumentException if data size is larger than FFT size
     */
    void realFft(List<double> data) {

        if (data.length > size) {
            throw new ArgumentError("data length ${data.length} is larger than FFT size = $size");
        }
        // apply padding
        if (size != data.length) {
            data = resize(data, size);
        }

        tableFFT(data);

        double theta = 2 * PI / size;
        double wpr = cos(theta);
        double wpi = sin(theta);
        double wjr = wpr;
        double wji = wpi;

        for (int j = 1; j <= size / 4; ++j) {
            int k = size ~/ 2 - j;
            double tkr = data[2 * k];    // real and imaginary parts of t_k  = t_(n/2 - j)
            double tki = data[2 * k + 1];
            double tjr = data[2 * j];    // real and imaginary parts of t_j
            double tji = data[2 * j + 1];

            double a = (tjr - tkr) * wji;
            double b = (tji + tki) * wjr;
            double c = (tjr - tkr) * wjr;
            double d = (tji + tki) * wji;
            double e = (tjr + tkr);
            double f = (tji - tki);

            // compute entry y[j]
            data[2 * j] = 0.5 * (e + (a + b));
            data[2 * j + 1] = 0.5 * (f + (d - c));

            // compute entry y[k]
            data[2 * k] = 0.5 * (e - (b + a));
            data[2 * k + 1] = 0.5 * ((d - c) - f);

            double temp = wjr;
            wjr = wjr * wpr - wji * wpi;
            wji = temp * wpi + wji * wpr;
        }

        // compute final y0 and y_{N/2}, store in data[0], data[1]
        double temp = data[0];
        data[0] += data[1];
        data[1] = temp - data[1];
    }

    /**
     * fills sin and cos tables
     */
    void _initialize() {
        // forward pass
        int mmax = 1, pos = 0;
        while (size > mmax) {
            int istep = 2 * mmax;
            double theta = PI / mmax;
            double wr = 1.0, wi = 0.0;
            double wpi = sin(theta);
            // compute in a slightly slower yet more accurate manner
            double wpr = sin(theta / 2);
            wpr = -2 * wpr * wpr;
            for (int m = 0; m < istep; m += 2) {
                cosTable[pos] = wr;
                sinTable[pos++] = wi;
                double t = wr;
                wr = wr * wpr - wi * wpi + wr;
                wi = wi * wpr + t * wpi + wi;
            }
            mmax = istep;
        }
    }

    /**
     * Swap data indices whenever index i has binary digits reversed from index j, where data is two doubles per index.
     *
     * @param data data array
     * @param n    n
     */
    void reverse(Float64List data, int n) {
        // bit reverse the indices. This is exercise 5 in section
        // 7.2.1.1 of Knuth's TAOCP the idea is a binary counter
        // in k and one with bits reversed in j
        int j = 0, k = 0; // Knuth R1: initialize
        int top = n ~/ 2;  // this is Knuth's 2^(n-1)
        while (true) {
            // Knuth R2: swap - swap j+1 and k+2^(n-1), 2 entries each
            double t = data[j + 2];
            data[j + 2] = data[k + n];
            data[k + n] = t;
            t = data[j + 3];
            data[j + 3] = data[k + n + 1];
            data[k + n + 1] = t;
            if (j > k) { // swap two more
                // j and k
                t = data[j];
                data[j] = data[k];
                data[k] = t;
                t = data[j + 1];
                data[j + 1] = data[k + 1];
                data[k + 1] = t;
                // j + top + 1 and k+top + 1
                t = data[j + n + 2];
                data[j + n + 2] = data[k + n + 2];
                data[k + n + 2] = t;
                t = data[j + n + 3];
                data[j + n + 3] = data[k + n + 3];
                data[k + n + 3] = t;
            }
            // Knuth R3: advance k
            k += 4;
            if (k >= n)
                break;
            // Knuth R4: advance j
            int h = top;
            while (j >= h) {
                j -= h;
                h = h~/2;
            }
            j += h;
        } // bit reverse loop
    }

    /**
     * Calculates energy. [fftValues] contains interleaved complex numbers as [real0, imag0, real1, imag1...]
     * Returning energy value list is half the size of the [fftValues]. 
     */
    List<double> energy(List<double> fftValues) {
      List<double> energy = new List<double>(fftValues.length ~/ 2);
        for (int i = 0; i < fftValues.length; i += 2) {
            energy[i >> 1] = fftValues[i] * fftValues[i] + fftValues[i + 1] * fftValues[i + 1];
        }
        return energy;
    }

    FrameData process(FrameData input) {
      List<double> dataToProcess = input.copyOfData;      
      if (input.size > size) {
        throw new ArgumentError("data length ${dataToProcess.length} is larger than FFT size = $size");
      }
      // apply padding
      if (size != dataToProcess.length) {
        dataToProcess = resize(dataToProcess, size);
      }
      realFft(dataToProcess);
      return input.copy(energy(dataToProcess));
    }

}

