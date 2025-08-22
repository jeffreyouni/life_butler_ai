import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:core/core.dart' show Logger;

import 'router/app_router.dart';
import 'providers/app_providers.dart';
import 'services/app_initializer.dart';
import 'services/embedding_status.dart';

final _logger = Logger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    _logger.warning('Could not load .env file: $e');
  }

  // Initialize basic data (without embeddings)
  await AppInitializer.initializeBasicData();

  runApp(
    const ProviderScope(
      child: LifeButlerApp(),
    ),
  );
}

class LifeButlerApp extends ConsumerStatefulWidget {
  const LifeButlerApp({super.key});

  @override
  ConsumerState<LifeButlerApp> createState() => _LifeButlerAppState();
}

class _LifeButlerAppState extends ConsumerState<LifeButlerApp> {
  bool _embeddingsInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize embeddings after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEmbeddings();
    });
  }
  
  Future<void> _initializeEmbeddings() async {
    if (_embeddingsInitialized || EmbeddingStatus.isComplete || EmbeddingStatus.isGenerating) {
      _logger.debug('Embeddings already initialized or in progress, skipping...');
      return;
    }
    
    try {
      // Wait for RAG pipeline to be available
      final ragPipeline = await ref.read(ragPipelineProvider.future);
      final database = AppInitializer.getSharedDatabase();
      
      // Initialize embeddings
      await AppInitializer.initializeEmbeddings(database, ragPipeline);
      
      setState(() {
        _embeddingsInitialized = true;
      });
      
      _logger.info('✅ Embeddings initialization completed in main.dart');
    } catch (e) {
      _logger.warning('❌ Could not initialize embeddings: $e');
      // Don't set _embeddingsInitialized to true on error, so it can be retried
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Life Butler AI',
      routerConfig: router,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
