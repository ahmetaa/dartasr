library dartasr;

import 'lm_vocabulary.dart';

abstract class NgramLm {

  /// Returns Log uni-gram probability value. id must be in vocabulary limits.
  double getUnigramProb(int id);

  
  /// Returns Log N-Gram probability.
  /// this is a back-off model, it makes with necessary back-off calculations when necessary
  double getNgramProb(List<int> ids);

  /// order of the lm. Typically 2 or 3 for an ASR lm.
  int get order();

  /// Gets the total count of a particular gram size
  int gramCount(int order);

  /// Vocabulary of this model.
  LmVocabulary get vocabulary;  
}
