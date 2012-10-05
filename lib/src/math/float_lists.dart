library dartasr;

import 'dart:scalarlist';

/**
 * multiplies two gloat lists and result is written to the [first] list.
 */
void multiplyToFirst(Float64List first, Float64List second) {
    for (int i = 0; i < first.length; i++) {
        first[i] = first[i] * second[i];
    }
}

