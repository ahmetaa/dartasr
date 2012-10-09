import 'package:dartasr/src/math/gaussian.dart';
import 'dart:math';
import 'dart:scalarlist';

main() {
  perfGaussian(10);
  perfGaussian(100000);  
}

void perfGaussian(int size) {
    Random random = new Random();
    final int dimension = 39;
    List<List<double>> data = new List<List<double>>(size);
    for (int i = 0; i < data.length; i++) {
      data[i] = new List<double>(dimension);
      for (int j = 0; j < dimension; j++) {
        data[i][j] = random.nextInt(10) / 10 + 0.1;
      }
    }
    var d = new MultivariateDiagonalGaussian(data[0], data[1]);
    Stopwatch sw = new Stopwatch()..start();
    double tot = 0.0;    
    for (int i = 0; i<data.length; ++i) {
      tot = tot + d.linearLikelihood(data[i]);
    }
    print("linear: ${sw.elapsedInMs()} total=$tot");
    sw..reset()..start();
    tot = 0.0;
    for (int i = 0; i<data.length; ++i) {
      tot= tot+ d.logLikelihood(data[i]);
    }
    print("Log: ${sw.elapsedInMs()} total=$tot");
  
}