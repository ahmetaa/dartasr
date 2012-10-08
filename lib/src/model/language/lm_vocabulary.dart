/// Represents the vocabulary of the language model.
class LmVocabulary {
    List<String> vocabulary;
   var vocabularyIndexMap = new Map<String, int>();

    LmVocabulary(this.vocabulary) {
        generateMap(vocabulary);
    }

    void generateMap(List<String> vocabulary) {
        // construct vocabulary index lookup.
        for (int i = 0; i < vocabulary.length; i++) {
            if (vocabularyIndexMap.containsKey(vocabulary[i]))
                print("Warning: Vocabulary has duplicate item: $vocabulary[i]");
            else
                vocabularyIndexMap.put(vocabulary[i], i);
        }
    }

    int get size()=> vocabulary.length;

    String getWord(int index) {
        return vocabulary[index];
    }

    int getId(String word) {
        int k = vocabularyIndexMap.get(word);
        return k == null ? -1 : k;
    }

    String getAsSingleString(List<int> index) {
        StringBuffer sb = new StringBuffer();
        for (int i in index) {
            if (isValid(i))
                sb.add(vocabulary[i]).add(" ");
            else
                sb.add("???").add(" ");
        }
        return '${sb.toString()}${index.toString()}';
    }

    bool checkIfAllValidId(List<int> ids) {
        for (int id in ids) {
            if (isValid(id))
                return false;
        }
        return true;
    }

    bool isValid(int id) {
        return id >= 0 && id < vocabulary.length;
    }

    /**
     * returns the vocabulary id list for a word list. if a word is unknown, -1 is returned as its vocabulary id.
     */
    List<int> getIds(List<String> words) {
      List<int> ids = new List<int>(words.length);
        int i = 0;
        for (String word in words) {
            if (!vocabularyIndexMap.containsKey(word))
                ids[i] = -1;
            else
                ids[i] = vocabularyIndexMap.get(word);
            i++;
        }
        return ids;
    }
}
