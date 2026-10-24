import '../../domain/entities/vision_models.dart';

const visionKnowledge = <String, VisionKnowledge>{
  'Bacterial_Blight': VisionKnowledge(
    name: 'Hawar Daun Bakteri',
    description:
        'Gejala dapat berupa garis berair yang berkembang menjadi area menguning hingga mengering pada daun.',
    recommendation:
        'Pisahkan tanaman yang tampak bergejala, hindari pemupukan nitrogen berlebih, dan minta petugas lapangan mengonfirmasi kondisi tanaman.',
  ),
  'Brown_Spot': VisionKnowledge(
    name: 'Bercak Cokelat',
    description:
        'Bercak cokelat berbentuk oval dapat muncul pada daun dan mengganggu kemampuan tanaman berfotosintesis.',
    recommendation:
        'Periksa kecukupan hara dan kondisi drainase. Gunakan benih sehat pada siklus berikutnya dan konsultasikan pengendalian dengan penyuluh.',
  ),
  'Healthy': VisionKnowledge(
    name: 'Tanaman Tampak Sehat',
    description:
        'Model tidak menemukan pola penyakit yang dominan dari kelas yang dikenalnya.',
    recommendation:
        'Lanjutkan pemantauan rutin. Hasil ini bukan jaminan bahwa tanaman bebas dari semua penyakit atau gangguan.',
  ),
  'Leaf_Blast': VisionKnowledge(
    name: 'Blas Daun',
    description:
        'Lesi berbentuk belah ketupat dengan bagian tengah pucat dapat berkaitan dengan blas daun.',
    recommendation:
        'Kurangi kelembapan berkepanjangan, hindari nitrogen berlebih, dan konfirmasikan pada beberapa daun sebelum mengambil tindakan.',
  ),
  'Leaf_Scald': VisionKnowledge(
    name: 'Daun Terbakar',
    description:
        'Pola zona terang dan gelap dari ujung atau tepi daun dapat berkaitan dengan leaf scald.',
    recommendation:
        'Amati penyebaran gejala, jaga sanitasi area tanam, dan mintalah konfirmasi petugas pertanian setempat.',
  ),
  'Brown_Planthopper': VisionKnowledge(
    name: 'Wereng Batang Cokelat',
    description:
        'Serangga pengisap berwarna cokelat biasanya berada di bagian pangkal tanaman dan dapat menyebabkan tanaman mengering berkelompok.',
    recommendation:
        'Periksa pangkal rumpun di beberapa titik, jaga musuh alami, dan hindari penggunaan insektisida tanpa konfirmasi ambang kendali.',
  ),
  'Rice_Leaf_Roller': VisionKnowledge(
    name: 'Hama Putih Palsu',
    description:
        'Larva menggulung daun dan memakan jaringan hijau sehingga meninggalkan garis putih memanjang.',
    recommendation:
        'Buka beberapa daun yang tergulung untuk memastikan adanya larva dan konsultasikan tindakan berdasarkan tingkat serangan.',
  ),
  'Rice_Leafhopper': VisionKnowledge(
    name: 'Wereng Daun',
    description:
        'Wereng daun mengisap cairan tanaman dan beberapa jenis dapat berperan sebagai vektor penyakit.',
    recommendation:
        'Periksa bagian bawah daun pada beberapa rumpun, catat sebarannya, dan minta petugas lapangan memastikan spesies serta tindakan.',
  ),
};

VisionKnowledge knowledgeFor(String label) =>
    visionKnowledge[label] ??
    VisionKnowledge(
      name: label.replaceAll('_', ' '),
      description:
          'Kelas ini terdeteksi oleh model, tetapi informasi ringkas belum tersedia.',
      recommendation:
          'Jangan mengambil tindakan hanya dari hasil aplikasi. Mintalah pemeriksaan petugas lapangan.',
    );
