import 'dart:scalarlist';
import 'dart:math';
import '../frame_processor.dart';
import '../framedata.dart';
import '../../math/log_math.dart';
import '../../math/float_lists.dart';

/**
 * This applies Cepstral Mean Normalization to an array of Feature Vectors.
 * With this, features become more robust by reducing the effect of different recording mediums.
 * 
 * X = {x0, x2, ... xn-1}  n cepstral vectors.  
 * x' = Sum(x0..n-1)/n     this is the sample mean  
 * x^ = x - x'             normalized cepstral vectors.  
 * 
 * This operation is intended for a full utterance.
 * This class is stateful as it stores the mean values in it. It should be re-instantiated for each utterance if
 * Utterance based CMN is required.
 */
class BatchCmn {

    Float64List sums;
    int numberDataCepstra;

    BatchCmn(int featureLength) {
        sums = new Float64List(featureLength);
    }

    /// Applies Cepstral Mean Normalization to data. It uses the history of the perviously calculated mean values.
    void process(List<FrameData> cepstrums) {

        for (var input in cepstrums) {
            numberDataCepstra++;
            addToFirst(sums, input.data);
        }

        for (int i = 0; i < sums.length; i++) {
            sums[i] /= numberDataCepstra;
        }

        for (FrameData data in cepstrums) {
            substractFromFirst(data.data, sums);
        }
    }
}

