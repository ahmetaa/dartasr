import 'package:dartasr/src/math/gaussian.dart';
import 'dart:math';
import 'dart:scalarlist';

main() {
  perfGaussian();
}


void perfGaussian() {
    Random random = new Random();
    final int dimension = 39;
    List<List<double>> data = new List<List<double>>(100000);
    for (int i = 0; i < data.length; i++) {
      data[i] = new Float64List(dimension);
      for (int j = 0; j < dimension; j++) {
        data[i][j] = random.nextInt(10) / 10 + 0.1;
      }
    }
    var d = new MultivariateDiagonalGaussian(data[0], data[1]);
    Stopwatch sw = new Stopwatch()..start();
    for (int i = 0; i<data.length; ++i) {
      d.linearLikelihood(data[i]);
    }
    print("linear: ${sw.elapsedInMs()}");
    sw..reset()..start();
    for (int i = 0; i<data.length; ++i) {
      d.logLikelihood(data[i]);
    }
    print("Log: ${sw.elapsedInMs()}");
  
}