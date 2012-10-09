
import 'dart:io';
import '../sample/audio_sample_format.dart';

/**
 * Represents Riff Header Data. RIff headers are used as in wav file headers. It describes the nature of the sound
 * samples in the wav file. Header consists of several chunks. Structure is like this:
 *
 *   ------------------
 *   |  "RIFF"     [4] |
 *   |  size       [4] |
 *   |  "WAVE"     [4] |
 *   | --------------  |
 *   | | chunkId [4]|  |
 *   | | size    [4]|  |
 *   | | data [size]|  |
 *   | --------------  |
 *   |     .......     |
 *   | --------------  |
 *   | | chunkId [4]|  |
 *   | | size    [4]|  |
 *   | | data [size]|  |
 *   | --------------  |
 *   -------------------
 *
 *   chunkId's are integer representation of 4 Ascii characters. Such as "data" etc
 *   All data except [chunkId, RIFF and WAVE]  are written as Little-Endian.
 *
 */
/*
   class RiffHeaderData {

    int dataStartPosition;

    int dataChunkSizeLocation;

    int get riffChunkSizeLocation => 4;

    int get dataChunkSizeLocation => dataChunkSizeLocation;

    final int WAVE_VALUE = 0x57415645; // ASCII values for string "WAVE" concatenated in big-endian int form

    AudioSampleFormat format;

    int totalSamplesInBytes;

    var chunks = new List<Chunk>();

    RiffHeaderData(File file) {
        this(new DataInputStream(new FileInputStream(file)));
    }

    RiffHeaderData(UInt8Array headerData) {
        this(new DataInputStream(new ByteArrayInputStream(headerData)));
    }

    RiffHeaderData(InputStream dis) throws IOException {
            // load RIFF chunk information
            ChunkId chunkId = ChunkId.getFromInt(dis.readInt()); // load chunk id.
            if (chunkId != ChunkId.RIFF)
                throw new AudioFormatException(String.format("Unexpected chunk ID: %x. RIFF (%x) expected.", chunkId.val, ChunkId.RIFF.val));
            chunks.add(new Chunk(ChunkId.RIFF, getIntLE(dis), Bytes.toByteArray(WAVE_VALUE, true)));
            int waveVal = dis.readInt();
            if (waveVal != WAVE_VALUE) {
                throw new AudioFormatException(String.format("Unexpected RIFF type: %x. WAVE (%x) expected", waveVal, WAVE_VALUE));
            }
            dataStartPosition += 4 + 4 + 4; // RIFF+ChunkSize+WAVE

            // load other chunk information
            do {
                chunkId = ChunkId.getFromInt(dis.readInt()); // load chunk id.
                final int chunkSize = getIntLE(dis);
                Chunk chunk;
                if (chunkId != ChunkId.DATA) {
                    byte[] data = new byte[chunkSize];
                    dis.readFully(data);
                    chunk = new Chunk(chunkId, chunkSize, data);
                    dataStartPosition += chunk.chunkSize();
                    if (chunkId == ChunkId.FMT) {
                        format = loadFormat(data);
                    }
                } else {
                    chunk = new Chunk(chunkId, chunkSize);
                    totalSamplesInBytes = chunkSize;
                    dataStartPosition += 8;
                }
                chunks.add(chunk);
            }
            while (chunkId != ChunkId.DATA);

            dataChunkSizeLocation = dataStartPosition - 4;
    }

    int getIntLE(DataInputStream dis) throws IOException {
        byte[] buf4 = new byte[4];
        dis.readFully(buf4);
        return Bytes.toInt(buf4, false);
    }

    int getShortLE(DataInputStream dis) throws IOException {
        byte[] buf2 = new byte[2];
        dis.readFully(buf2);
        return Bytes.toInt(buf2, false);
    }

    private static class Chunk {
        ChunkId id;
        int dataSize;
        byte[] data; // this is used for some chunks. not for Data or RIFF chunks

        Chunk(ChunkId id, int dataSize) {
            this.id = id;
            this.dataSize = dataSize;
            data = new byte[0];
        }

        Chunk(ChunkId id, int size, byte[] chunkData) {
            this.id = id;
            this.dataSize = size;
            this.data = chunkData;
        }

        byte[] getAsByteArray() throws IOException {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            baos.write(toByteArray(id.val, true));
            baos.write(toByteArray(dataSize, false));
            baos.write(data);
            return baos.toByteArray();
        }

        int chunkSize() {
            return 4 + 4 + dataSize;
        }

        @Override
        public String toString() {
            return id.name + " size: " + dataSize + ", actual data=" + data.length;
        }
    }

    private AudioSampleFormat loadFormat(byte[] data) throws IOException {
        DataInputStream dis = new DataInputStream(new ByteArrayInputStream(data));
        final int encodingCode = getShortLE(dis);
        final int channels = getShortLE(dis);
        final int sampleRate = getIntLE(dis);
        dis.skipBytes(4 + 2);
        final int sampleSizeInBits = getShortLE(dis);
        dis.close();
        return new AudioSampleFormat.Builder().
                channels(channels).
                sampleRate(sampleRate).
                sampleSizeInBits(sampleSizeInBits).
                encoding(AudioSampleFormat.Encoding.fromWaveValue(encodingCode)).
                build();
    }

    public double timeSeconds() {
        return (double) totalSamplesInBytes / format.getBytesPerSample() / format.getSampleRate();
    }

    public static RiffHeaderData generate(AudioSampleFormat format, int totalSamplesInByte) throws IOException {
        byte[] fmtBytes = getFormatAsByteArray(format);
        LinkedList<Chunk> chunks = new LinkedList<>();

        // format
        Chunk fmt = new Chunk(ChunkId.FMT, fmtBytes.length, fmtBytes);
        chunks.add(fmt);

        // for a-law and mu-law we add "fact" chunk
        if (format.isCompressed()) {
            byte[] factData = Bytes.toByteArray(0x005d0000, true);
            Chunk fact = new Chunk(ChunkId.FACT, factData.length, factData);
            chunks.add(fact);
        }

        // "data" chunk. Only size information.
        Chunk data = new Chunk(ChunkId.DATA, totalSamplesInByte);
        chunks.add(data);

        // "riff" chunk. it is added to the beginning
        int chunkSizeSoFar = 0;
        for (Chunk chunk : chunks) {
            chunkSizeSoFar += chunk.chunkSize();
        }
        Chunk riff = new Chunk(ChunkId.RIFF, chunkSizeSoFar+4, Bytes.toByteArray(WAVE_VALUE, true));
        chunks.addFirst(riff);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        for (Chunk chunk : chunks) {
            baos.write(chunk.getAsByteArray());
        }
        return new RiffHeaderData(baos.toByteArray());
    }

    public byte[] asByteArray() {
        ByteArrayOutputStream baos = null;
        try {
            baos = new ByteArrayOutputStream();
            for (Chunk chunk : chunks) {
                baos.write(chunk.getAsByteArray());
            }
            return baos.toByteArray();
        } catch (IOException e) {
            e.printStackTrace();
            return new byte[0];
        } finally {
            IOs.closeSilently(baos);
        }
    }

    private static byte[] getFormatAsByteArray(AudioSampleFormat format) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        // AudioFormat , for PCM = 1, IEEE Float = 3, A-LAW = 6, MU-LAW=7, EXTENSIBLE= 0xFFFE .Little endian 2 Bytes.
        baos.write(toByteArray((short) format.getEncoding().waveEncodingValue, false));
        // Number of channels Mono = 1, Stereo = 2  Little Endian , 2 bytes.
        int channels = format.getChannels();
        baos.write(toByteArray((short) channels, false));
        // SampleRate (8000, 44100 etc.) little endian, 4 bytes
        int sampleRate = format.getSampleRate();
        baos.write(toByteArray(sampleRate, false));
        // byte rate (SampleRate * NumChannels * BitsPerSample/8) little endian, 4 bytes.
        baos.write(toByteArray(channels * sampleRate * format.getBytesPerSample(), false));
        // Block Allign == NumChannels * BitsPerSample/8  The number of bytes for one sample including all channels. LE, 2 bytes
        baos.write(toByteArray((short) (channels * format.getBytesPerSample()), false));
        // BitsPerSample (8, 16 etc.) LE, 2 bytes
        baos.write(toByteArray((short) format.getSampleSizeInBits(), false));
        baos.write(toByteArray((short) 0x0000, false)); // extended information byte count - 0
        return baos.toByteArray();
    }

    public int getDataStartPosition() {
        return dataStartPosition;
    }

    public AudioSampleFormat getFormat() {
        return format;
    }

    public int getTotalSamplesInBytes() {
        return totalSamplesInBytes;
    }

    public int getSampleCount() {
        return totalSamplesInBytes / format.getBytesPerSample();
    }

    public String toString() {
        return "[ Format: " + format.toString() + " , totalSamplesInBytes:" + totalSamplesInBytes + "]";
    }

}

class ChunkId {
  var RIFF = const ChunkId("RIFF");
  var FMT = const ChunkId("fmt ");
  var DATA = const ChunkId("data");  
  var FACT = const ChunkId("fact");  
  var WAVL = const ChunkId("wavl");  
  var SLNT = const ChunkId("slnt");
  var CUE = const ChunkId("cue "); 
  var PLST = const ChunkId("plst");
  var LIST = const ChunkId("list");  
  var LABL = const ChunkId("labl");
  var NOTE = const ChunkId("note");  
  var LTXT = const ChunkId("ltxt");  
  var SMPL = const ChunkId("smpl");  
  var INST = const ChunkId("inst");    

  String name;
  int valBE;
  int valLE;  

  ChunkId(this.name) {
    // big-endian int value of the ascii string
    valBE = 0;
    valLE = 0;
    int k = 0;
    for (int c in name.charCodes()) {
      valLE |= (c << (k*8));
      valBE = (valBE<<8) | c);
      k--;
    }
  }

  static ChunkId getFromInt(int intId) {
    for (ChunkId chunkId : ChunkId.values()) {
      if (chunkId.val == intId)
        return chunkId;
    }
    throw new AudioFormatException(String.format("Cannot identify Wave Chunk ID:%x", intId));
  }
}
*/
