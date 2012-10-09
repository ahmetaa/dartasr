library dartasr;

import 'dart:math';
import 'dart:scalarlist';

double LN0 = log(0);

double log10(double input) {
  return log(input)/LN10;
}

double log2(double input) {
  return log(input)/LN2;
}

const double _SCALE = 1000.0;

LogMath logMath = new LogMath();

/**
 * Calculates an approximation of log(a+b) when log(a) and log(b) are given using the formula
 * log(a+b) = log(b) + log(1 + exp(log(a)-log(b))) where log(b)>log(a)
 * This method is an approximation because it uses a lookup table for log(1 + exp(log(b)-log(a))) part
 * This is useful for log-probabilities where values vary between -30 < log(p) <= 0
 * if difference between values is larger than 20 (which means sum of the numbers will be very close to the larger
 * value in linear domain) large value is returned instead of the logSum calculation because effect of the other
 * value is negligible
 */
double logSum(double logA, double logB) {
  if (logA > logB) {
    double dif = logA - logB; // logA-logB because during lookup calculation dif is multiplied with -1
    return dif >= 30.0 ? logA : logA + logMath.logSumLookup[(dif * _SCALE).toInt()];
  } else {
    final double dif = logB - logA;
    return dif >= 30.0 ? logB : logB + logMath.logSumLookup[(dif * _SCALE).toInt()];
  }
}

/**
 * Calculates approximate logSum of log values using the <code> logSum(logA,logB) </code>
*
 * @param logValues log values to use in logSum calculation.
 * @return <p>log(a+b) value approximation
 */
double logSumAll(List<double> logValues) {
  double result = LN0;
  for (double logValue in logValues) {
    result = logSum(result, logValue);
  }
  return result;
}

/**
 * Exact calculation of log(a+b) using log(a) and log(b) with formula
 * log(a+b) = log(b) + log(1 + exp(log(b)-log(a))) where log(b)>log(a)
 */
double logSumExact(double logA, double logB) {
  if (logA == double.INFINITY || logA==double.NEGATIVE_INFINITY)
    return logB;
  if (logB == double.INFINITY || logB==double.NEGATIVE_INFINITY)
    return logA;
  if (logA > logB) {
    double dif = logA - logB;
    return dif >= 30 ? logA : logA + log(1 + exp(-dif));
  } else {
    double dif = logB - logA;
    return dif >= 30 ? logB : logB + log(1 + exp(-dif));
  }
}

class LogMath {  
  
  static final LogMath _singleton = new LogMath._internal();
  
  final logSumLookup = new List<double>(30000);
  
  factory LogMath() {
    return _singleton;
  }
  
  LogMath._internal() {
    for (int i = 0; i < logSumLookup.length; i++) {
      logSumLookup[i] = log(1.0 + exp(-i / _SCALE));
    }
  }    
}