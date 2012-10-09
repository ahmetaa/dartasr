library dartasr;
/**
 * Represents a context independent phone.
 * For LVSR in Turkish, this is usually the grapheme equivalent phones. Such as
 * word 'ali' is consist of three Phone a,l and i.
 * However this can represent finer or broader grain phonetic units. For English Phone number is larger than
 * the alphabet count for LVSR tasks.
 *
 * Fillers are also marked as Phones
 */
class Phone {

    final int index;
    final String _id;

    final bool filler; // whether this phone is a Filler (FIL)
    final bool silence; // whether this phone is Silence (SIL)

    static final Phone UNDEFINED = new Phone(0,"?",false);

    Phone(this.index, this._id, [this.filler=false, this.silence=false]) {
        if (index < 0 || index > 63) {
            throw new ArgumentError("Phone index must be between 1 and 63 (inclusive). But the phone with id=[$id] index is: $index");
        }
      
        if (!this.filler && silence)
            throw new ArgumentError("Silence must be marked as filler.");
    }

    String get id => _id;

    bool isNonSilenceFiller() => filler && !silence;
    
    String toString() => id.toString();
}

/**
 * Defines the position of this acoustic unit in a token. A token is usually a word or any morpheme.
 */
class PhoneticUnitPosition {
    static const BEGIN = const PhoneticUnitPosition("b", 1);   //at the beginning position of the token
    static const END =  const PhoneticUnitPosition("e", 2); // at the end position of the token
    static const SINGLE = const PhoneticUnitPosition("s", 3); //  a single letter token
    static const INTERNAL = const PhoneticUnitPosition("i", 4); // inside to the token
    static const UNDEFINED = const PhoneticUnitPosition("?", 0); // undefined position in the token. Usually used for Context Independent PhoneticUnit HMMs

    final String shortName;
    final int index;

    const PhoneticUnitPosition(this.shortName, this.index);
}


/**
 * PositionalTriphone represents a special context and position dependent Acoustic Unit.
 * It is represented with a base phone, phones on the left and right of it and the position of this unit in a word.
 */
class PositionalTriphone {

    static int POSITION_INDEPENDENT_MASK = 0x3ff;

    Phone base;
    Phone leftContext;
    Phone rightContext;
    /**
     * A unique identifier for the Triphone. If this is generated in the constructor,
     * it is formatted as : Base(Left,Right)-Position
     */
    String id;

    /**
     * this is a unique index built with 6 bit Phone indexes and 3 bit position index. PositionIndex|Left|Right|Base
     */
    int index;

    PhoneticUnitPosition position;

    static final PositionalTriphone UNDEFINED = new PositionalTriphone(
            Phone.UNDEFINED,
            Phone.UNDEFINED,
            Phone.UNDEFINED,
            PhoneticUnitPosition.UNDEFINED);

    /**
     * Constructs a Triphone. id and index are generated inside the constructor.
     *
     * @param base         basePhone which resides in the middle of the Triphone
     * @param leftContext  left Context Phone
     * @param rightContext right Context Phone
     * @param position     position of this Triphone
     */
    PositionalTriphone(this.base, this.leftContext, this.rightContext, this.position) {
        this.id = generateId(base, leftContext, rightContext, position);
    }

    static String generateId(Phone base, Phone leftContext, Phone rightContext, PhoneticUnitPosition position) {
        return "${base.id}(${leftContext.id},${rightContext.id})-{$position.shortName}";
    }

    static int generateIndex(Phone base, Phone leftContext, Phone rightContext, PhoneticUnitPosition position) {
        return position.index << 18 | leftContext.index << 12 | rightContext.index << 6 | base.index;
    }

    static int getIndexForPosition(int index, PhoneticUnitPosition position) {
        return  ( index & POSITION_INDEPENDENT_MASK ) | position.index << 18;
    }

    /**
     * Generates a Triphone from a Context Independent Phone. Left and Right Context are defined as Phone.UNDEFINED
     *
     * @param phone contenxt independent phone
     * @return Triphone representing a context independent phone.
     */
    PositionalTriphone.fromContextIndependentPhone(Phone phone) {
        return new PositionalTriphone(phone, Phone.UNDEFINED, Phone.UNDEFINED, PhoneticUnitPosition.UNDEFINED);
    }

    /**
     * Generates a Triphone from a Context Independent Phone. Left and Right Context are defined as Phone.UNDEFINED
     *
     * @param phone contenxt independent phone
     * @return Triphone representing a context independent phone.
     */
    static int contextIndependentPhoneIndex(Phone phone) {
        return generateIndex(phone, Phone.UNDEFINED, Phone.UNDEFINED, PhoneticUnitPosition.UNDEFINED);
    }

    String getId() {
        return id;
    }

    int getIndex() {
        return index;
    }

    boolean isFiller() {
        return base.filler;
    }

    String toString() {
        return id;
    }

    bool operator ==(other) {
      if(!(other is PositionalTriphone))
        return false;
      return index==other.index;
    }
    
    int hashCode() {
        return index;
    }
}


main() {
  var p = new Phone(1,"a");
  print(p);
}
