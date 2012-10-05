library dartasr;

import 'framedata.dart';

/** This is an interface for classes that makes operations on a FrameData object. */
abstract class FrameProcessor {
  
  /**
   * It takes a FrameData [input] and applies an operation to it's data.
   * Implementer may modify the data in the input directly or return a new FrameData after the process.
   * the resulting FrameData's data amount may be different than the input data count.
   */
  abstract FrameData process(FrameData input);
  
}
