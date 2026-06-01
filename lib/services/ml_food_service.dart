import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MLFoodService {

  static Future<String> detectFood(
      String imagePath,
      ) async {

    final inputImage =
    InputImage.fromFilePath(
      imagePath,
    );

    final imageLabeler =
    ImageLabeler(
      options:
      ImageLabelerOptions(
        confidenceThreshold: 0.5,
      ),
    );

    final labels =
    await imageLabeler.processImage(
      inputImage,
    );

    await imageLabeler.close();

    if (labels.isEmpty) {

      return 'Unknown Food';
    }

    labels.sort(
          (a, b) =>
          b.confidence.compareTo(
            a.confidence,
          ),
    );

    return labels.first.label;
  }
}