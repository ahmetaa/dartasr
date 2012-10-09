library dartasr;

/// multiplies two float lists and result is written to the [first] list.
void multiplyToFirst(List<double> first, List<double> second) {
    for (int i = 0; i < first.length; i++) {
        first[i] = first[i] * second[i];
    }
}

/// sums two float lists and result is written to the [first] list.
void addToFirst(List<double> first, List<double> second) {
    for (int i = 0; i < first.length; i++) {
        first[i] = first[i] + second[i];
    }
}

/// substracts [second] list from the [first] list. Result is written to the [first] list.
void substractFrom(List<double> first, List<double> second) {
    for (int i = 0; i < first.length; i++) {
        first[i] = first[i] - second[i];
    }
}

void checkNotEmpty(List<double> darray) {
  if (darray == null) {
    throw new ArgumentError("List is null!");
  } else if (darray.length == 0)
    throw new ArgumentError("List is empty!");
}

/// expands or crops a list. if expanded, padded elements are set to 0.
List<double> resize(List<double> list, int newLength) {
  if(newLength==list.length) return list;
  var res = new List<double>(newLength);
  if(newLength<list.length) res.setRange(0, newLength, list);
  else {
    res.setRange(0, list.length, list);
    for(int j = list.length; j<newLength;++j)
      res[j]=0.0;
  }    
}
