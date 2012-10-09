library dartasr;

import 'dart:scalarlist';
import 'dart:math';
import 'log_math.dart';
import 'float_lists.dart';

/**
 * Represents a 1 dimensional Gaussian function
 */
class UnivariateGaussian {
    double mean;
    double variance;
    double linearConstant;
    double logConstant;

    UnivariateGaussian(this.mean, this.variance) {
        linearConstant = 1 / (sqrt(2 * PI * variance));
        logConstant = -0.5 * (log(2 * PI) + log(variance));
    }

    linearLikelihood(double input) {
        double a = input - mean;
        return linearConstant * exp((-a * a) / (2 * variance));
    }

    logLikelihood(double input) {
        double a = input - mean;
        return logConstant - (a * a / variance);
    }

    String toString() {
        return "mean=$mean variance=$variance";
    }
}

/**
 * Represents a Multivariate Gaussian function with diagonal covariance matrix.
 * Normally a multivariate Gauss function with diagonal covariance matrix is:
 * f(x) = MUL[d=1..D] (1/(sqrt(2 *PI * var[d])) exp(-0.5 * (x[d] - mean[d])^2 / var[d]))
 * 
 * But we are interested in log likelihoods. Calculating linear likelihood values is expensive because of sqrt and exp
 * operations. And because this operation will likely to be done millions of times during recognition it needs to be very
 * effective. log likelihood is much more efficient to calculate. Therefore it becomes
 * log f(x) = -0.5*SUM[d=1..D] ( log(2*PI) + log(var[d]) +  (x[d] - mean[d])^2 / var[d]) )
 * 
 * This can be effectively calculated if right side is split as follows
 * log f(x) = -0.5*SUM[d=1..D] ( log(2*PI) + log(var[d]) ) - 0.5* SUM[1..D]((xd - mean[d])^2 / var[d])
 * 
 * Here first part can be pre-computed as:
 * C = -0.5*log(2*PI)*D -0.5 SUM[d=1..D](log(var[d]))
 * 
 * For making remaining part faster, we pre-compute -0.5*1/var[d] values as well and store them as negative half precision
 * negativeHalfPrecisions[d]. So result log likelihood computation becomes:
 * log f(x) = C - SUM[d=1..D]((xd - mean[d])^2 * negativeHalfPrecisions[d])
 */
class MultivariateDiagonalGaussian {

  List<double> means;
  List<double> variances;
  List<double> negativeHalfPrecisions;
  double logPrecomputedDistance;

    /**
     * Constructs a Diagonal Covariance Matrix Multivariate Gaussian with given mean and variance vector.
     *
     * @param means     mean vector
     * @param variances variance vector representing variance matrix diagonal.
     */
    MultivariateDiagonalGaussian(this.means, this.variances) {
        // check for null and length inequality
        checkNotEmpty(means);
        checkNotEmpty(variances);

        // instead of using [-0.5 * 1/var[d]] during likelihood calculation we pre-compute the values.
        // This saves 1 mul 1 div operation.
        negativeHalfPrecisions = new List<double>(variances.length);
        for (int i = 0; i < negativeHalfPrecisions.length; i++) {
            negativeHalfPrecisions[i] = -0.5 / variances[i];
        }

        // calculate the precomputed distance.
        // -0.5*SUM[d=1..D] ( log(2*PI) + log(var[d]) ) = -0.5*log(2*PI)*D -0.5 SUM[d=1..D](log(var[d]))
        double val = -0.5 * log(2 * PI) * variances.length;
        for (double variance in variances) {
            val -= (0.5 * log(variance));
        }
        logPrecomputedDistance = val;
    }

    /// Calculates log likelihood of the given vector [data].
    double logLikelihood(List<double> data) {
        double result = logPrecomputedDistance;
        for (int i = 0; i < means.length; i++) {
            final double dif = data[i] - means[i];
            result += (dif * dif * negativeHalfPrecisions[i]);
        }
        return result;
    }

    /// Calculates linear likelihood for the given vector. Note that this is a slow operation.
    double linearLikelihood(List<double> data) {
        double result = 1.0;
        for (int i = 0; i < means.length; i++) {
            double meanDif = data[i] - means[i];
            double v = (1 / sqrt(2 * PI * variances[i])) * exp(meanDif * meanDif * negativeHalfPrecisions[i]);
            result *= v;
        }
        return result;
    }

    /// dimension of this multiavriate Gaussian.
    get dimension() => means.length;

}

class UnivariateGmm {

    List<UnivariateGaussian> gaussians;
    List<double> weights;

    UnivariateGmm(this.gaussians, this.weights);

    double linearLikelihood(double val) {
        double result = 0.0;
        for (int i = 0; i < gaussians.length; i++) {
            result += gaussians[i].linearLikelihood(val) * weights[i];
        }
        return result;
    }
}

/**
 * GMM's are used for representing arbitrary probability distributions with weighted sums of Gaussians.
 * Likelihood of an input of a GMM is calculated as below:
 * 
 * f(x) = SUM[k=1..M] (weight[k]*Gauss(x|means[k],covariance[k]))
 * In log domain what we have have to do is to calculate   log( SUM[k=1..M] weight*Gauss[k](x) )
 * However, what we have is log(Gauss[k](x)) and log(weight[k])
 * Therefore We need to apply the LogSum function one at a time
 * 
 * var logResult;
 * for k = 1..M
 *   logResult = LOGSUM(logResult , (log Gauss[k](x) + logWeight[k] ))
 */
class MultivariateGmm  {

     List<double> logMixtureWeights;
     List<MultivariateDiagonalGaussian> gaussians;

     MultivariateGmm( this.logMixtureWeights,  this.gaussians);

     double logLikelihood(List<double> data) {
        double logTotal = LN0;
        for (int i = 0; i < gaussians.length; ++i) {
            // we calculate the gauss value first.
            // Then apply weight (it is a sum because of the log)
            // then accumulate it to the total. Here for speed, logSum method is used
            logTotal = logSum(logTotal, gaussians[i].logLikelihood(data) + logMixtureWeights[i]);
        }
        return logTotal;
    }

    /// amount How many distributions are mixed in this model
    int get mixtureAmount() => logMixtureWeights.length;

    /// Dimension of the Gaussian
    int get dimension() => gaussians[0].dimension();
}


