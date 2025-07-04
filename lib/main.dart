import 'package:flutter/material.dart';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/animation.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/timer.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'package:shake/shake.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 1), () {
      FlutterNativeSplash.remove();
    });
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 85, 192, 64),
    );

    printColorScheme(colorScheme);

    return MaterialApp(
      title: 'Newe Spotter',
      theme: ThemeData(colorScheme: colorScheme),
      navigatorObservers: [routeObserver],
      home: const MyHomePage(title: 'Newe Spotter'),
    );
  }
}

void printColorScheme(ColorScheme scheme) {
  print('Primary: ${scheme.primary}');
  print('OnPrimary: ${scheme.onPrimary}');
  print('PrimaryContainer: ${scheme.primaryContainer}');
  print('OnPrimaryContainer: ${scheme.onPrimaryContainer}');

  print('Secondary: ${scheme.secondary}');
  print('OnSecondary: ${scheme.onSecondary}');
  print('SecondaryContainer: ${scheme.secondaryContainer}');
  print('OnSecondaryContainer: ${scheme.onSecondaryContainer}');

  print('Tertiary: ${scheme.tertiary}');
  print('OnTertiary: ${scheme.onTertiary}');
  print('TertiaryContainer: ${scheme.tertiaryContainer}');
  print('OnTertiaryContainer: ${scheme.onTertiaryContainer}');

  print('Background: ${scheme.background}');
  print('OnBackground: ${scheme.onBackground}');
  print('Surface: ${scheme.surface}');
  print('OnSurface: ${scheme.onSurface}');
  print('Error: ${scheme.error}');
  print('OnError: ${scheme.onError}');
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RouteAware {
  File? _imageFile;
  final MyWanderingGame game = MyWanderingGame();

  final ImagePicker _picker = ImagePicker();

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final File imageFile = File(photo.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdjustImageScreen(initialImage: imageFile),
        ),
      );
    }

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final File imageFile = File(image.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdjustImageScreen(initialImage: imageFile),
        ),
      );
    }
  }

  void onTractorButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavedImageGrid()),
    );
  }

  void checkForChanges() {
    game.updateSheep();
  }

  @override
  void initState() {
    super.initState();
    checkForChanges(); // Run on first load
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!); // 👈 subscribe
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // 👈 unsubscribe
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when another screen is popped and this becomes visible
    checkForChanges();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.agriculture),
            tooltip: 'Done',
            onPressed: () {
              onTractorButtonPressed();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Builder(
                  builder: (context) {
                    final bgColor = Theme.of(
                      context,
                    ).colorScheme.inversePrimary;
                    game.setBackgroundColor(bgColor);
                    return GameWidget(game: game);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'leftBtn',
              onPressed: () {
                _pickFromGallery();
              },
              child: const Icon(Icons.collections),
            ),
            Text(
              'Add Sheep',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            FloatingActionButton(
              heroTag: 'rightBtn',
              onPressed: () {
                _takePicture();
              },
              child: const Icon(Icons.camera_alt),
            ),
          ],
        ),
      ),
    );
  }
}

class MyWanderingGame extends FlameGame {
  late SpriteAnimation rightRunAnim;
  late SpriteAnimation leftRunAnim;
  late SpriteAnimation rightIdleAnim;
  late SpriteAnimation leftIdleAnim;
  late SpriteAnimation rightBeeeAnim;
  late SpriteAnimation leftBeeeAnim;
  late SpriteAnimation rightBeeeUAnim;
  late SpriteAnimation leftBeeeUAnim;
  late int N = 0; // Number of sheep
  bool init = false;

  late ShakeDetector shakeDetector;
  bool _shakeDetected = false; // Flag to indicate if a shake was detected
  final List<WanderingSheep> sheepList = [];

  late Color _bgColor;

  void setBackgroundColor(Color color) {
    _bgColor = color;
  }

  @override
  Color backgroundColor() => _bgColor;

  void updateSheep() async {
    if (init) {
      int newN = await readCsvFile();
      if (N != newN) {
        N = newN;
        // Clear existing sheep
        for (final sheep in sheepList) {
          remove(sheep);
        }
        sheepList.clear();

        // Recreate sheep
        final rand = Random();
        for (int i = 0; i < N; i++) {
          final sheep = WanderingSheep(
            rightRunAnim: rightRunAnim,
            leftRunAnim: leftRunAnim,
            rightIdleAnim: rightIdleAnim,
            leftIdleAnim: leftIdleAnim,
            rightBeeeAnim: rightBeeeAnim,
            leftBeeeAnim: leftBeeeAnim,
            rightBeeeUAnim: rightBeeeUAnim,
            leftBeeeUAnim: leftBeeeUAnim,
            position: Vector2(
              (rand.nextDouble() * 0.5 + 0.25) * 200,
              (rand.nextDouble() * 0.5 + 0.25) * 400,
            ),
            size: Vector2(64, 64),
            velocity: Vector2(0, 0),
          );
          sheepList.add(sheep);
          add(sheep);
        }
      }
    }
  }

  Future<int> readCsvFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/image_metadata.csv');

    if (!await file.exists()) {
      return 0; // Return 0 if the file does not exist
    }

    final contents = await file.readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(contents);

    return rows.length;
  }

  @override
  Future<void> onLoad() async {
    final rightRunSheet = SpriteSheet(
      image: await images.load('SheepRun.png'),
      srcSize: Vector2(64, 64),
    );

    final leftRunSheet = SpriteSheet(
      image: await images.load('SheepRunLeft.png'),
      srcSize: Vector2(64, 64),
    );

    final rightIdleSheet = SpriteSheet(
      image: await images.load('SheepIdle.png'),
      srcSize: Vector2(64, 64),
    );

    final leftIdleSheet = SpriteSheet(
      image: await images.load('SheepIdleLeft.png'),
      srcSize: Vector2(64, 64),
    );

    final rightBeeeSheet = SpriteSheet(
      image: await images.load('Sheep_beee.png'),
      srcSize: Vector2(64, 64),
    );

    final leftBeeeSheet = SpriteSheet(
      image: await images.load('Sheep_beeeLeft.png'),
      srcSize: Vector2(64, 64),
    );

    final rightBeeeUSheet = SpriteSheet(
      image: await images.load('Sheep_beeeU.png'),
      srcSize: Vector2(64, 64),
    );

    final leftBeeeUSheet = SpriteSheet(
      image: await images.load('Sheep_beeeLeftU.png'),
      srcSize: Vector2(64, 64),
    );

    rightRunAnim = rightRunSheet.createAnimation(row: 0, stepTime: 0.2);
    leftRunAnim = leftRunSheet.createAnimation(row: 0, stepTime: 0.2);

    rightIdleAnim = rightIdleSheet.createAnimation(row: 0, stepTime: 0.2);
    leftIdleAnim = leftIdleSheet.createAnimation(row: 0, stepTime: 0.2);

    rightBeeeAnim = rightBeeeSheet.createAnimation(row: 0, stepTime: 0.2);
    leftBeeeAnim = leftBeeeSheet.createAnimation(row: 0, stepTime: 0.2);

    rightBeeeUAnim = rightBeeeUSheet.createAnimation(row: 0, stepTime: 0.2);
    leftBeeeUAnim = leftBeeeUSheet.createAnimation(row: 0, stepTime: 0.2);

    final rand = Random();
    N = await readCsvFile();

    for (int i = 0; i < N; i++) {
      final sheep = WanderingSheep(
        rightRunAnim: rightRunAnim,
        leftRunAnim: leftRunAnim,
        rightIdleAnim: rightIdleAnim,
        leftIdleAnim: leftIdleAnim,
        rightBeeeAnim: rightBeeeAnim,
        leftBeeeAnim: leftBeeeAnim,
        rightBeeeUAnim: rightBeeeUAnim,
        leftBeeeUAnim: leftBeeeUAnim,
        position: Vector2(
          (rand.nextDouble() * 0.5 + 0.25) * 200,
          (rand.nextDouble() * 0.5 + 0.25) * 400,
        ),
        size: Vector2(64, 64),
        velocity: Vector2(0, 0),
      );
      sheepList.add(sheep);
      add(sheep);
    }
    shakeDetector = ShakeDetector.waitForStart(
      onPhoneShake: (ShakeEvent event) {
        // Just mark a flag here; don't update game state directly
        _shakeDetected = true;
      },
    );

    shakeDetector.startListening();
    init = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_shakeDetected) {
      _shakeDetected = false;
      // Notify your sheep or do your game logic here safely in the update loop
      for (final sheep in sheepList) {
        sheep.onShake();
      }
    }
  }

  @override
  void onRemove() {
    shakeDetector.stopListening();
    super.onRemove();
  }
}

class WanderingSheep extends SpriteAnimationComponent with HasGameRef {
  late SpriteAnimation rightRunAnim;
  late SpriteAnimation leftRunAnim;
  late SpriteAnimation rightIdleAnim;
  late SpriteAnimation leftIdleAnim;
  late SpriteAnimation rightBeeeAnim;
  late SpriteAnimation leftBeeeAnim;
  late SpriteAnimation rightBeeeUAnim;
  late SpriteAnimation leftBeeeUAnim;
  Vector2 velocity;
  late Timer directionChangeTimer;
  bool isRigged = false;
  bool isRight = true;

  WanderingSheep({
    required this.rightRunAnim,
    required this.leftRunAnim,
    required this.rightIdleAnim,
    required this.leftIdleAnim,
    required this.rightBeeeAnim,
    required this.leftBeeeAnim,
    required this.rightBeeeUAnim,
    required this.leftBeeeUAnim,
    required Vector2 position,
    required Vector2 size,
    required this.velocity,
  }) : super(
         animation: velocity.x >= 0 ? rightRunAnim : leftRunAnim,
         position: position,
         size: size,
       );

  @override
  Future<void> onLoad() async {
    final rand = Random();
    final time = (rand.nextDouble() * 0.5 + 0.5) * 5;
    animation = rightIdleAnim;
    directionChangeTimer = Timer(time, repeat: true, onTick: _changeDirection)
      ..start();
  }

  void onShake() {
    animation = isRight ? rightBeeeUAnim : leftBeeeUAnim;
    velocity = Vector2.zero();
    isRigged = true;
  }

  void _changeDirection() {
    final rand = Random();

    if (!isRigged) {
      if (rand.nextDouble() > 0.2) {
        // Change to idle animation
        if (rand.nextDouble() > 0.95) {
          animation = isRight ? rightBeeeAnim : leftBeeeAnim;
        } else {
          if (rand.nextDouble() > 0.99) {
            animation = isRight ? rightBeeeUAnim : leftBeeeUAnim;
            isRigged = true;
          } else {
            animation = isRight ? rightIdleAnim : leftIdleAnim;
          }
        }

        velocity = Vector2.zero();
      } else {
        velocity = Vector2(
          rand.nextDouble() * 100 - 50, // -50 to +50
          rand.nextDouble() * 100 - 50,
        );

        isRight = velocity.x >= 0;
        animation = isRight ? rightRunAnim : leftRunAnim;
      }
    } else {
      if (rand.nextDouble() > 0.90) {
        isRigged = false;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    directionChangeTimer.update(dt);
    position += velocity * dt;

    // Bounce off edges
    if (position.x < 0 || position.x + size.x > gameRef.size.x) {
      velocity.x = -velocity.x;
      animation = velocity.x >= 0 ? rightRunAnim : leftRunAnim;
    }
    if (position.y < 0 || position.y + size.y > gameRef.size.y) {
      velocity.y = -velocity.y;
    }
  }
}

class SpriteSheetWidget extends FlameGame with TapDetector {
  // @override
  // void onTapDown(TapDownInfo info) {
  // }

  @override
  Future<void> onLoad() async {
    final spriteSheet = SpriteSheet(
      image: await images.load('Sheep_beee.png'),
      srcSize: Vector2(64.0, 64.0),
    );
    final spriteSize = Vector2(128.0, 128.0);

    final animation = spriteSheet.createAnimation(row: 0, stepTime: 0.1, to: 7);
    final component1 = SpriteAnimationComponent(
      animation: animation,
      scale: Vector2(0.4, 0.4),
      position: Vector2(100, 30),
      size: spriteSize,
    );

    add(component1);
  }
}

class AdjustImageScreen extends StatefulWidget {
  final File initialImage;

  const AdjustImageScreen({super.key, required this.initialImage});

  @override
  State<AdjustImageScreen> createState() => _AdjustImageScreenState();
}

class _AdjustImageScreenState extends State<AdjustImageScreen> {
  late File _imageFile;
  late File _cropImageFile;

  final List<String> assetPaths = List.generate(
    6,
    (index) => 'assets/images/bad$index.png',
  );

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
    _cropImageFile = widget.initialImage;
  }

  void _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(
        ratioX: 1,
        ratioY: 1,
      ), // 🔲 square crop
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          lockAspectRatio: true, // prevents user from changing the ratio
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true, // also lock for iOS
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _cropImageFile = File(croppedFile.path);
      });
    }
  }

  void _processImage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessImageScreen(imageFile: _cropImageFile),
      ),
    );
  }

  void onHomeButtonPressed() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Adjust Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Done',
            onPressed: () {
              onHomeButtonPressed();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      _cropImageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // round the corners
                        ),
                        backgroundColor: const Color.fromARGB(
                          30,
                          0,
                          0,
                          0,
                        ), // semi-transparent
                        foregroundColor: Colors.white, // text/icon color
                      ),
                      onPressed: () {
                        _cropImage(_imageFile);
                      },
                      child: const Icon(Icons.crop, size: 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary, // 🔵 background color
                    child: Image.asset(assetPaths[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'leftBtn',
              onPressed: () {
                onHomeButtonPressed();
              },
              child: const Icon(Icons.arrow_back),
            ),
            FloatingActionButton(
              heroTag: 'rightBtn',
              onPressed: () {
                _processImage();
              },
              child: const Icon(Icons.search),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessImageScreen extends StatefulWidget {
  final File imageFile;

  const ProcessImageScreen({super.key, required this.imageFile});

  @override
  State<ProcessImageScreen> createState() => _ProcessImageScreenState();
}

class _ProcessImageScreenState extends State<ProcessImageScreen> {
  late File _imageFile;
  late final Interpreter _interpreter;
  late final String _label;
  late final String _description;
  late final bool _isLoading;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _isLoading = true;
    runModel();
  }

  void updateScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NameSheepScreen(
          imageFile: _imageFile,
          label: _label,
          description: _description,
        ),
      ),
    );
  }

  Future<void> runModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/m9_fullSheep.tflite',
    );

    if (_interpreter == null) {
      throw Exception('Failed to load model');
    } else {
      final inputShape = _interpreter.getInputTensor(0).shape;
      final input = preprocessImage(_imageFile, inputShape[1]);
      final output = List.filled(36, 0.0).reshape([1, 36]);

      _interpreter.run(input, output);
      List<String> labels = await loadLabelsFromAssets(
        'assets/models/m9_fullSheep_labels.txt',
      );
      List<String> descriptions = await loadLabelsFromAssets(
        'assets/models/sheep_descriptions.txt',
      );

      double max = output[0][0];
      int index = 0;
      for (int i = 1; i < output[0].length; i++) {
        if (output[0][i] > max) {
          max = output[0][i];
          index = i;
        }
      }
      _label = labels[index];
      _description = descriptions[index];
      updateScreen();
    }
  }

  Future<List<String>> loadLabelsFromAssets(String assetPath) async {
    final content = await rootBundle.loadString(assetPath);
    return content.split('\n');
  }

  List<List<List<List<double>>>> preprocessImage(File imageFile, int size) {
    final bytes = imageFile.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Image decode failed');

    final resized = img.copyResize(decoded, width: size, height: size);

    final inputTensor = [
      List.generate(
        size,
        (y) => List.generate(size, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r * 1.0, pixel.g * 1.0, pixel.b * 1.0];
        }),
      ),
    ];

    return inputTensor;
  }

  void onHomeButtonPressed() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Process Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Done',
            onPressed: () {
              onHomeButtonPressed();
            },
          ),
        ],
      ),
      body: Center(child: Text("Processing image...")),
    );
  }
}

class NameSheepScreen extends StatefulWidget {
  final File imageFile;
  final String label;
  final String description;

  const NameSheepScreen({
    super.key,
    required this.imageFile,
    required this.label,
    required this.description,
  });

  @override
  State<NameSheepScreen> createState() => _NameSheepScreenState();
}

class _NameSheepScreenState extends State<NameSheepScreen> {
  late File _imageFile;
  late String _label;
  late String _sheepName;
  late String _description;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _label = widget.label;
    _description = widget.description;
  }

  void _saveSheepName() {
    setState(() {
      _sheepName = _controller.text;
      // Here you can save the sheep name to a database or file if needed

      saveImageToDisk(_imageFile).then((savedFile) {
        getCsvFile().then((csvFile) {
          csvFile.writeAsString(
            '$_sheepName`$_label`$_description`${savedFile.path}\n',
            mode: FileMode.append,
          );
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SavedImageGrid()),
        );
      });
    });
  }

  Future<File> saveImageToDisk(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/saved_images");
    await folder.create(recursive: true);
    final newFile = File(
      '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.png',
    );
    return await imageFile.copy(newFile.path);
  }

  Future<File> getCsvFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/image_metadata.csv');
    if (!file.existsSync()) {
      await file.create();
    }
    return file;
  }

  void onHomeButtonPressed() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("$_label"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Done',
            onPressed: () {
              onHomeButtonPressed();
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(
                    _imageFile,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Name your sheep',
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0)),
              Text(_description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'leftBtn',
              onPressed: () {
                onHomeButtonPressed();
              },
              child: const Icon(Icons.delete_forever),
            ),
            FloatingActionButton(
              heroTag: 'rightBtn',
              onPressed: () {
                _saveSheepName();
              },
              child: const Icon(Icons.agriculture),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedImageGrid extends StatefulWidget {
  const SavedImageGrid({super.key});

  @override
  State<SavedImageGrid> createState() => _SavedImageGridState();
}

class _SavedImageGridState extends State<SavedImageGrid> {
  List<File> _imageFiles = [];
  List<List<String>> _csvData = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/saved_images");

    await readCsvFile();
    List<File> imageFiles = [];

    for (List<String> row in _csvData) {
      if (row.isNotEmpty && row.length >= 3) {
        final imagePath = row[3];
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          imageFiles.add(imageFile);
        } else {}
      }
    }

    setState(() {
      _imageFiles = imageFiles;
    });
  }

  Future<int> readCsvFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/image_metadata.csv');

    if (!await file.exists()) {
      throw Exception("File not found: $file");
    }

    final contents = await file.readAsString();
    final rows = const CsvToListConverter(
      eol: '\n',
      fieldDelimiter: '`',
    ).convert(contents);

    _csvData = rows
        .map((row) => row.map((e) => e.toString()).toList())
        .toList();

    return 1;
  }

  void deleteSheep(int index) async {
    Navigator.of(context).pop();

    if (index < 0 || index >= _imageFiles.length) return;

    final fileToDelete = _imageFiles[index];
    await fileToDelete.delete();

    setState(() {
      _imageFiles.removeAt(index);
      _csvData.removeAt(index);
    });

    // Update CSV file
    final dir = await getApplicationDocumentsDirectory();
    final csvFile = File('${dir.path}/image_metadata.csv');
    final csvContent = const ListToCsvConverter().convert(_csvData);
    await csvFile.writeAsString(csvContent);
  }

  void onHomeButtonPressed() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Widget _buildSheepName(BuildContext context, int index) {
    final name = _csvData.isNotEmpty
        ? _csvData[index][0]
        : 'Sheep ${index + 1}';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(name, style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  Widget _buildImageViewer(int index) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1,
          maxScale: 4,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.file(_imageFiles[index], fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildSheepBreed(BuildContext context, int index) {
    final breed = _csvData.isNotEmpty ? _csvData[index][1] : 'Breed';
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          breed,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FloatingActionButton(
            heroTag: 'leftBtn',
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Slaughter'),
                  content: const Text(
                    'Are you sure you want to slaughter this sheep?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) deleteSheep(index);
            },
            child: const Icon(Icons.delete_forever),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Your Flock"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Done',
            onPressed: () {
              onHomeButtonPressed();
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _imageFiles.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withAlpha(200),
                  insetPadding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSheepName(context, index),
                      _buildImageViewer(index),
                      _buildSheepBreed(context, index),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _csvData.isNotEmpty
                              ? _csvData[index][2]
                              : 'Description not available',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDeleteButton(context, index),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_imageFiles[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
