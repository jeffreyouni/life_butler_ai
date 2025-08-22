import 'dart:math';
import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'package:core/core.dart';
import 'embedding_status.dart';

/// Comprehensive SeedData implementation with fully English sample content
class ComprehensiveSeedData {
  static final _logger = Logger('ComprehensiveSeedDataEn');

  final LifeButlerDatabase database;
  final RagPipeline? ragPipeline;
  final Random _random = Random();

  ComprehensiveSeedData(this.database, {this.ragPipeline});

  /// Generate comprehensive sample data for testing
  Future<void> generateSampleData() async {
    await generateBasicData();

    // Generate embeddings for RAG system if available
    if (ragPipeline != null) {
      _logger.info('Generating embeddings for RAG system...');
      await _generateRagEmbeddings();
      _logger.info('Generated embeddings');
    }
  }

  /// Generate basic data without embeddings
  Future<void> generateBasicData() async {
    _logger.info('Generating comprehensive English sample data...');

    try {
      // Clear existing data first
      await database.delete(database.financeRecords).go();
      await database.delete(database.meals).go();
      await database.delete(database.events).go();
      await database.delete(database.education).go();
      await database.delete(database.career).go();
      await database.delete(database.journals).go();
      await database.delete(database.healthMetrics).go();
      await database.delete(database.tasksHabits).go();
      await database.delete(database.relations).go();
      await database.delete(database.mediaLogs).go();
      await database.delete(database.travelLogs).go();
      await database.delete(database.attachments).go();
      await database.delete(database.embeddings).go();
      _logger.info('Cleared existing data');

      // Create default user
      await _createDefaultUser();

      // Generate comprehensive data for the past 2 months
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 60));

      await _generateComprehensiveEvents(startDate, endDate);
      await _generateComprehensiveMeals(startDate, endDate);
      await _generateComprehensiveFinanceRecords(startDate, endDate);
      await _generateEducationData();
      await _generateCareerData();
      await _generateJournalEntries(startDate, endDate);
      await _generateHealthMetrics(startDate, endDate);
      await _generateTasksAndHabits();
      await _generateRelationsData();
      await _generateMediaLogs(startDate, endDate);
      await _generateTravelLogs();
      await _generateAttachments();

      _logger.info('Generated comprehensive English sample data');
    } catch (e) {
      _logger.error('Error generating sample data: $e');
    }
  }

  /// Generate only embeddings (assumes data already exists)
  Future<void> generateEmbeddingsOnly() async {
    if (ragPipeline == null) {
      _logger.warning('No RAG pipeline available for embedding generation');
      return;
    }

    try {
      _logger.info('Generating embeddings for existing data...');
      await _generateRagEmbeddings();
      _logger.info('Generated embeddings');
    } catch (e) {
      _logger.error('Error generating embeddings: $e');
    }
  }

  /// Create default user
  Future<void> _createDefaultUser() async {
    try {
      await database.into(database.users).insert(
        UsersCompanion.insert(
          id: 'test-user-1',
          username: 'John Student',
          email: 'john@example.com',
          preferencesJson: const Value({'language': 'en-US'}),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrReplace,
      );
      _logger.info('Created default user');
    } catch (e) {
      _logger.error('Error creating user: $e');
    }
  }

  /// Generate comprehensive events
  Future<void> _generateComprehensiveEvents(DateTime start, DateTime end) async {
    final events = <EventsCompanion>[];

    // Variety of events for better chat/testing coverage
    final eventTypes = [
      // Education related
      {'title': 'Advanced Mathematics Class', 'category': 'education', 'location': 'Building A, Room 101', 'description': 'Studying calculus and linear algebra'},
      {'title': 'Computer Programming Lab', 'category': 'education', 'location': 'Computer Lab', 'description': 'Hands-on practice with Python and Java'},
      {'title': 'English Listening Class', 'category': 'education', 'location': 'Language Lab', 'description': 'Improving English listening and speaking'},
      {'title': 'Data Structures & Algorithms', 'category': 'education', 'location': 'Building B, Room 205', 'description': 'Sorting, trees, graphs, and more'},
      {'title': 'Machine Learning Seminar', 'category': 'education', 'location': 'Academic Hall', 'description': 'Deep learning and AI frontier topics'},

      // Social activities
      {'title': 'Club Meetup', 'category': 'social', 'location': 'Student Activity Center', 'description': 'Programming club tech sharing'},
      {'title': 'Classmates Dinner', 'category': 'social', 'location': 'Off-campus Restaurant', 'description': 'Birthday celebration with roommates'},
      {'title': 'Class Party', 'category': 'social', 'location': 'KTV', 'description': 'Post-finals party to relax'},
      {'title': 'Academic Talk', 'category': 'social', 'location': 'Grand Auditorium', 'description': 'Renowned professor talks about AI'},
      {'title': 'Volunteer Service', 'category': 'social', 'location': 'Community Center', 'description': 'Participating in community service'},

      // Study and research
      {'title': 'Library Study', 'category': 'study', 'location': 'Library', 'description': 'Preparing for final exams'},
      {'title': 'Group Discussion', 'category': 'study', 'location': 'Seminar Room', 'description': 'Teamwork on course project'},
      {'title': 'Paper Writing', 'category': 'study', 'location': 'Dormitory', 'description': 'Finishing term papers and reports'},
      {'title': 'Lab Report', 'category': 'study', 'location': 'Dormitory', 'description': 'Organizing data and analysis results'},

      // Health and exercise
      {'title': 'Workout', 'category': 'health', 'location': 'Gymnasium', 'description': 'Basketball practice and cardio'},
      {'title': 'Morning Run', 'category': 'health', 'location': 'Campus Track', 'description': 'Daily run to stay healthy'},
      {'title': 'Yoga Class', 'category': 'health', 'location': 'Gym', 'description': 'Relieve stress and improve flexibility'},
      {'title': 'Swimming', 'category': 'health', 'location': 'Swimming Pool', 'description': 'Swim training and relaxation'},

      // Entertainment
      {'title': 'Watch a Movie', 'category': 'entertainment', 'location': 'Cinema', 'description': 'Latest sci‑fi release'},
      {'title': 'Shopping', 'category': 'entertainment', 'location': 'Mall', 'description': 'Buying necessities and clothes'},
      {'title': 'Game Time', 'category': 'entertainment', 'location': 'Dormitory', 'description': 'Playing games with roommates'},
      {'title': 'Concert', 'category': 'entertainment', 'location': 'Concert Hall', 'description': 'Enjoying classical music'},

      // Daily life
      {'title': 'Laundry', 'category': 'daily', 'location': 'Laundromat', 'description': 'Weekly laundry routine'},
      {'title': 'Clean Dorm', 'category': 'daily', 'location': 'Dormitory', 'description': 'Tidying up and cleaning'},
      {'title': 'Grocery Run', 'category': 'daily', 'location': 'Supermarket', 'description': 'Buying daily supplies and snacks'},
      {'title': 'Haircut', 'category': 'daily', 'location': 'Barbershop', 'description': 'Trim and tidy up'},

      // Career
      {'title': 'Internship Interview', 'category': 'career', 'location': 'Company Office', 'description': 'Interview for summer internship'},
      {'title': 'Job Prep', 'category': 'career', 'location': 'Dormitory', 'description': 'Resume polishing and interview prep'},
      {'title': 'Career Planning Talk', 'category': 'career', 'location': 'Career Center', 'description': 'Employment outlook and career development'},
    ];

    var currentDate = start;
    while (currentDate.isBefore(end)) {
      final isWeekday = currentDate.weekday <= 5;
      final eventCount = isWeekday ? _random.nextInt(3) + 1 : _random.nextInt(2);

      for (int i = 0; i < eventCount; i++) {
        if (_random.nextDouble() > 0.2) { // 80% chance of events
          final eventType = eventTypes[_random.nextInt(eventTypes.length)];
          final hour = _random.nextInt(14) + 8; // 8 AM to 10 PM

          events.add(EventsCompanion.insert(
            id: _generateId(),
            userId: 'test-user-1',
            title: eventType['title']!,
            date: currentDate.add(Duration(hours: hour)),
            description: Value(eventType['description']!),
            tagsJson: Value({
              'category': eventType['category'],
              'priority': _getRandomPriority(),
              'mood': _getRandomMood(),
              'weather': _getRandomWeather(),
            }),
            location: Value(eventType['location']!),
            createdAt: currentDate,
            updatedAt: currentDate,
          ));
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    for (final event in events) {
      await database.into(database.events).insert(event, mode: InsertMode.insertOrIgnore);
    }

    _logger.info('Generated ${events.length} events');
  }

  /// Generate comprehensive meals with costs
  Future<void> _generateComprehensiveMeals(DateTime start, DateTime end) async {
    final meals = <MealsCompanion>[];

    var currentDate = start;
    while (currentDate.isBefore(end)) {
      // Breakfast (70% chance)
      if (_random.nextDouble() > 0.3) {
        final isHomeMade = _random.nextDouble() > 0.4;
        final mealName = isHomeMade ? _getRandomHomeMadeBreakfast() : _getRandomTakeoutBreakfast();
        final cost = _random.nextDouble() * (isHomeMade ? 8 : 20) + (isHomeMade ? 3 : 8);

        meals.add(MealsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          name: mealName,
          itemsJson: Value({
            'restaurant': isHomeMade ? null : _getRandomRestaurant(),
            'homeMade': isHomeMade,
            'cost': cost,
            'mealType': 'breakfast',
            'ingredients': isHomeMade ? _getRandomIngredients() : null,
            'nutrition': {
              'protein': _random.nextInt(15) + 5,
              'carbs': _random.nextInt(40) + 20,
              'fat': _random.nextInt(10) + 3,
            },
            'satisfaction': _random.nextInt(3) + 3, // 3-5 stars
            'healthiness': _random.nextInt(3) + 3, // 3-5 stars
          }),
          caloriesInt: Value(_random.nextInt(300) + 200),
          time: currentDate.add(Duration(hours: 7, minutes: _random.nextInt(120))),
          location: Value(isHomeMade ? 'Dorm' : 'Takeout'),
          notes: Value(isHomeMade ? 'Homemade breakfast, balanced nutrition' : 'Takeout breakfast, quick and convenient'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Lunch (80% chance)
      if (_random.nextDouble() > 0.2) {
        final isHomeMade = _random.nextDouble() > 0.6; // More takeout for lunch
        final mealName = isHomeMade ? _getRandomHomeMadeLunch() : _getRandomTakeoutLunch();
        final cost = _random.nextDouble() * (isHomeMade ? 15 : 35) + (isHomeMade ? 5 : 15);

        meals.add(MealsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          name: mealName,
          itemsJson: Value({
            'restaurant': isHomeMade ? null : _getRandomRestaurant(),
            'homeMade': isHomeMade,
            'cost': cost,
            'mealType': 'lunch',
            'ingredients': isHomeMade ? _getRandomIngredients() : null,
            'nutrition': {
              'protein': _random.nextInt(25) + 15,
              'carbs': _random.nextInt(60) + 30,
              'fat': _random.nextInt(15) + 8,
            },
            'satisfaction': _random.nextInt(3) + 3,
            'healthiness': _random.nextInt(3) + 3,
            'spiciness': _getRandomSpiciness(),
          }),
          caloriesInt: Value(_random.nextInt(400) + 400),
          time: currentDate.add(Duration(hours: 11, minutes: _random.nextInt(120))),
          location: Value(isHomeMade ? 'Dorm' : 'Takeout'),
          notes: Value(isHomeMade ? 'Homemade lunch, healthy and budget-friendly' : 'Takeout lunch, ${_getRandomTakeoutComment()}'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Dinner (90% chance)
      if (_random.nextDouble() > 0.1) {
        final isHomeMade = _random.nextDouble() > 0.5;
        final mealName = isHomeMade ? _getRandomHomeMadeDinner() : _getRandomTakeoutDinner();
        final cost = _random.nextDouble() * (isHomeMade ? 20 : 40) + (isHomeMade ? 8 : 20);

        meals.add(MealsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          name: mealName,
          itemsJson: Value({
            'restaurant': isHomeMade ? null : _getRandomRestaurant(),
            'homeMade': isHomeMade,
            'cost': cost,
            'mealType': 'dinner',
            'ingredients': isHomeMade ? _getRandomIngredients() : null,
            'nutrition': {
              'protein': _random.nextInt(30) + 20,
              'carbs': _random.nextInt(70) + 40,
              'fat': _random.nextInt(20) + 10,
            },
            'satisfaction': _random.nextInt(3) + 3,
            'healthiness': _random.nextInt(3) + 3,
            'spiciness': _getRandomSpiciness(),
            'temperature': _getRandomTemperature(),
          }),
          caloriesInt: Value(_random.nextInt(500) + 400),
          time: currentDate.add(Duration(hours: 17, minutes: _random.nextInt(180))),
          location: Value(isHomeMade ? 'Dorm' : 'Takeout'),
          notes: Value(isHomeMade ? 'Homemade dinner, hearty and nutritious' : 'Takeout dinner, ${_getRandomTakeoutComment()}'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Snacks (40% chance)
      if (_random.nextDouble() > 0.6) {
        final snackName = _getRandomSnack();
        final cost = _random.nextDouble() * 15 + 5; // 5-20 USD

        meals.add(MealsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          name: snackName,
          itemsJson: Value({
            'homeMade': false,
            'cost': cost,
            'mealType': 'snack',
            'category': _getRandomSnackCategory(),
            'satisfaction': _random.nextInt(3) + 3,
            'healthiness': _random.nextInt(3) + 2, // snacks are usually less healthy
          }),
          caloriesInt: Value(_random.nextInt(200) + 50),
          time: currentDate.add(Duration(hours: 14, minutes: _random.nextInt(240))),
          location: Value(_getRandomSnackLocation()),
          notes: Value('Casual snack — ${_getRandomSnackComment()}'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    for (final meal in meals) {
      await database.into(database.meals).insert(meal, mode: InsertMode.insertOrIgnore);
    }

    _logger.info('Generated ${meals.length} meals');
  }

  /// Generate comprehensive finance records - key for spending patterns
  Future<void> _generateComprehensiveFinanceRecords(DateTime start, DateTime end) async {
    final records = <FinanceRecordsCompanion>[];

    var currentDate = start;
    while (currentDate.isBefore(end)) {
      // Takeout spending (60% chance)
      if (_random.nextDouble() > 0.4) {
        final amount = _random.nextDouble() * 30 + 15; // 15-45 USD
        final restaurant = _getRandomRestaurant();
        final food = _getRandomTakeoutFood();

        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('USD'),
          time: currentDate.add(Duration(hours: _random.nextInt(12) + 8)),
          category: const Value('takeout'),
          tagsJson: Value({
            'tags': ['food', 'takeout', 'dining'],
            'restaurant': restaurant,
            'meal_type': _getRandomMealType(),
            'payment_method': _getRandomPaymentMethod(),
          }),
          notes: Value('Takeout order — $food (from $restaurant)'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Grocery shopping (40% chance)
      if (_random.nextDouble() > 0.6) {
        final amount = _random.nextDouble() * 80 + 20; // 20-100 USD
        final items = _getRandomGroceryItems();
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('USD'),
          time: currentDate.add(Duration(hours: _random.nextInt(8) + 10)),
          category: const Value('groceries'),
          tagsJson: Value({
            'tags': ['food', 'groceries', 'shopping'],
            'store_type': _getRandomGroceryStore(),
            'items': items,
          }),
          notes: Value('Grocery run — ${items.join(', ')}'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Transportation expenses (daily chance)
      if (_random.nextDouble() > 0.5) {
        final transportType = _getRandomTransportType();
        final amount = _getTransportCost(transportType);

        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('USD'),
          time: currentDate.add(Duration(hours: _random.nextInt(16) + 6)),
          category: const Value('transportation'),
          tagsJson: Value({
            'tags': ['transport', 'daily'],
            'transport_type': transportType,
            'route': _getRandomRoute(),
          }),
          notes: Value('Transport — $transportType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Entertainment expenses (30% chance)
      if (_random.nextDouble() > 0.7) {
        final entertainmentType = _getRandomEntertainment();
        final amount = _getEntertainmentCost(entertainmentType);

        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('USD'),
          time: currentDate.add(Duration(hours: _random.nextInt(8) + 14)),
          category: const Value('entertainment'),
          tagsJson: Value({
            'tags': ['entertainment', 'leisure'],
            'activity_type': entertainmentType,
            'location': _getRandomEntertainmentLocation(),
          }),
          notes: Value('Entertainment — $entertainmentType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Education expenses (weekly chance on Wednesday)
      if (currentDate.weekday == 3 && _random.nextDouble() > 0.6) {
        final educationType = _getRandomEducationExpense();
        final amount = _getEducationCost(educationType);

        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('USD'),
          time: currentDate,
          category: const Value('education'),
          tagsJson: Value({
            'tags': ['education', 'learning'],
            'expense_type': educationType,
          }),
          notes: Value('Education — $educationType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Health expenses (random chance)
      if (_random.nextDouble() > 0.85) {
        final healthType = _getRandomHealthExpense();
        final amount = _getHealthCost(healthType);

        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('USD'),
          time: currentDate,
          category: const Value('healthcare'),
          tagsJson: Value({
            'tags': ['health', 'medical'],
            'service_type': healthType,
          }),
          notes: Value('Healthcare — $healthType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Shopping expenses (20% chance)
      if (_random.nextDouble() > 0.8) {
        final shoppingType = _getRandomShopping();
        final amount = _getShoppingCost(shoppingType);

        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('USD'),
          time: currentDate,
          category: const Value('shopping'),
          tagsJson: Value({
            'tags': ['shopping', 'retail'],
            'item_type': shoppingType,
            'store': _getRandomStore(),
          }),
          notes: Value('Shopping — $shoppingType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Weekly income (allowance) — Monday
      if (currentDate.weekday == 1) {
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'income',
          amount: 120.0, // weekly allowance
          currency: const Value('USD'),
          time: currentDate,
          category: const Value('allowance'),
          tagsJson: const Value({
            'tags': ['allowance', 'income', 'family'],
            'source': 'family_support',
          }),
          notes: const Value('Weekly allowance — family support'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      // Bi-weekly part-time income — Friday (roughly)
      if (currentDate.weekday == 5 && (currentDate.day % 14 == 0)) {
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'income',
          amount: 300.0,
          currency: const Value('USD'),
          time: currentDate,
          category: const Value('part_time'),
          tagsJson: const Value({
            'tags': ['income', 'work', 'part_time'],
            'job_type': 'tutoring',
          }),
          notes: const Value('Part-time income — tutoring'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    for (final record in records) {
      await database.into(database.financeRecords).insert(record, mode: InsertMode.insertOrIgnore);
    }

    _logger.info('Generated ${records.length} finance records');
  }

  /// Education data
  Future<void> _generateEducationData() async {
    final educations = <EducationCompanion>[
      // High School
      EducationCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        schoolName: 'Beijing No. 1 High School',
        degree: const Value('High School Diploma'),
        major: const Value('Science Track'),
        startDate: DateTime(2015, 9, 1),
        endDate: Value(DateTime(2018, 6, 30)),
        notes: const Value('Strong scores in math and physics; provincial medal in math contest.'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // University
      EducationCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        schoolName: 'Tsinghua University',
        degree: const Value('Bachelor\'s Degree'),
        major: const Value('Computer Science and Technology'),
        startDate: DateTime(2018, 9, 1),
        endDate: Value(DateTime(2022, 6, 30)),
        notes: const Value('GPA 3.8/4.0 (top 10%). Open-source contributor; academic scholarship.'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Master (current)
      EducationCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        schoolName: 'Tsinghua University',
        degree: const Value('Master\'s Degree'),
        major: const Value('Artificial Intelligence'),
        startDate: DateTime(2022, 9, 1),
        endDate: Value(DateTime(2025, 6, 30)),
        notes: const Value('Focus on machine learning and deep learning; current thesis on NLP.'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final education in educations) {
      await database.into(database.education).insert(education);
    }
    _logger.info('Generated education data: ${educations.length} records');
  }

  /// Career data
  Future<void> _generateCareerData() async {
    final careers = <CareerCompanion>[
      // Internship 1
      CareerCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        company: 'Tencent Technology',
        role: 'Software Engineering Intern',
        startDate: DateTime(2020, 7, 1),
        endDate: Value(DateTime(2020, 9, 1)),
        achievementsJson: const Value({
          'achievement1': 'Contributed to WeChat Mini Program backend',
          'achievement2': 'Optimized DB queries (≈30% faster)',
          'achievement3': 'Recognized as Outstanding Intern',
        }),
        notes: const Value('Worked on backend APIs; learned large-scale system design.'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Internship 2
      CareerCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        company: 'ByteDance',
        role: 'Algorithm Engineering Intern',
        startDate: DateTime(2021, 7, 1),
        endDate: Value(DateTime(2021, 10, 1)),
        achievementsJson: const Value({
          'achievement1': 'Improved recommendation model',
          'achievement2': 'Implemented A/B testing framework',
          'achievement3': 'Achieved ~15% uplift in offline metrics',
        }),
        notes: const Value('Focused on recommendation algorithms with modern DL stack.'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Part-time (current)
      CareerCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        company: 'Smart Education Tech Co.',
        role: 'Machine Learning Engineer (Part-time)',
        startDate: DateTime(2023, 3, 1),
        endDate: const Value(null),
        achievementsJson: const Value({
          'achievement1': 'Built AI-assisted teaching system',
          'achievement2': 'Developed student behavior analytics',
          'achievement3': 'Piloted in 5 schools',
        }),
        notes: const Value('Applied research to production for education products.'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final career in careers) {
      await database.into(database.career).insert(career);
    }
    _logger.info('Generated career data: ${careers.length} records');
  }

  /// Journal entries
  Future<void> _generateJournalEntries(DateTime start, DateTime end) async {
    final journals = <JournalsCompanion>[];

    final journalTopics = [
      ['study', 'research', 'paper'],
      ['life', 'mood', 'reflection'],
      ['project', 'coding', 'tech'],
      ['exercise', 'health', 'training'],
      ['social', 'friends', 'gathering'],
      ['reading', 'knowledge', 'growth'],
      ['travel', 'explore', 'experience'],
      ['family', 'care', 'love'],
    ];

    final journalContents = [
      '''# Today\'s Study Summary

I focused on new deep learning papers, especially improvements to Transformer architectures. Found an interesting attention optimization that may help my research.

## Key Findings
- New positional encoding boosts long-context handling
- Training efficiency improved by ~20%
- Plan to share at next week\'s group meeting

Tomorrow I\'ll dig deeper into implementation details.''',

      '''# Life Thoughts

Grad school has been stressful but rewarding. I learn something new every day. The challenges are real, but solving problems brings great satisfaction.

Had a discussion with my advisor today and got valuable feedback. Grateful for the guidance.

## Mood
😊 Overall positive and optimistic about the future.''',

      '''# Project Progress

Wrapped up the first iteration of the recommender system with:

1. User behavior data collection
2. Feature engineering
3. Model training & evaluation
4. Online inference service

## Tech Stack
- Python + PyTorch
- FastAPI + Redis
- PostgreSQL + Docker

Next step: tune the model to hit target metrics by next week.''',

      '''# Workout Log

Hit the campus gym for 1.5 hours and felt great afterwards.

## Today\'s Session
- Treadmill 30 minutes (6 km)
- Strength training 45 minutes
- Stretching 15 minutes

Consistent exercise really boosts study efficiency. Keep going! 💪''',

      '''# Reading Notes

Read Chapter 8 of *Deep Learning* about CNNs.

## Concepts
- Convolution math
- Pooling mechanisms
- Activation functions

Theory + practice = real understanding.''',

      '''# Social

Hotpot with classmates today. Everyone has their own struggles, but we\'re all growing.

## Takeaways
- Talk to people more
- Rest matters
- Friendship is precious''',
    ];

    final totalDays = end.difference(start).inDays;
    final journalFrequency = (totalDays / 15).ceil(); // roughly every 4 days

    for (int i = 0; i < journalFrequency; i++) {
      final entryDate = start.add(Duration(days: _random.nextInt(totalDays)));
      final topics = journalTopics[_random.nextInt(journalTopics.length)];
      final content = journalContents[_random.nextInt(journalContents.length)];
      final mood = _random.nextInt(10) + 1; // 1-10

      journals.add(JournalsCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        contentMd: content,
        moodInt: Value(mood),
        topicsJson: Value({
          for (int i = 0; i < topics.length; i++) 'topic_$i': topics[i]
        }),
        createdAt: entryDate,
        updatedAt: entryDate,
      ));
    }

    for (final journal in journals) {
      await database.into(database.journals).insert(journal);
    }
    _logger.info('Generated journal entries: ${journals.length} records');
  }

  /// (Legacy) Simple finance records generator (kept for compatibility if needed)
  Future<void> _generateFinanceRecords(DateTime start, DateTime end) async {
    final financeRecords = <FinanceRecordsCompanion>[];
    var currentDate = start;
    while (currentDate.isBefore(end)) {
      financeRecords.add(FinanceRecordsCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        type: 'expense',
        amount: _random.nextDouble() * 100,
        time: currentDate,
        category: const Value('general'),
        tagsJson: const Value({'tag1': 'example'}),
        notes: const Value('Sample finance record'),
        createdAt: currentDate,
        updatedAt: currentDate,
      ));
      currentDate = currentDate.add(const Duration(days: 1));
    }
    for (final record in financeRecords) {
      await database.into(database.financeRecords).insert(record);
    }
    _logger.info('Generated ${financeRecords.length} finance records');
  }

  /// Health metrics
  Future<void> _generateHealthMetrics(DateTime start, DateTime end) async {
    final healthMetrics = <HealthMetricsCompanion>[];
    var currentDate = start;
    while (currentDate.isBefore(end)) {
      healthMetrics.add(HealthMetricsCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        metricType: 'weight',
        valueNum: 55 + _random.nextDouble() * 25, // 55-80 kg
        unit: 'kg',
        time: currentDate,
        notes: const Value('Sample health metric'),
        createdAt: currentDate,
        updatedAt: currentDate,
      ));
      currentDate = currentDate.add(const Duration(days: 1));
    }
    for (final metric in healthMetrics) {
      await database.into(database.healthMetrics).insert(metric);
    }
    _logger.info('Generated ${healthMetrics.length} health metrics');
  }

  /// Media logs
  Future<void> _generateMediaLogs(DateTime start, DateTime end) async {
    final mediaLogs = <MediaLogsCompanion>[];
    var currentDate = start;
    while (currentDate.isBefore(end)) {
      mediaLogs.add(MediaLogsCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        title: 'Sample Media',
        mediaType: 'movie',
        time: currentDate,
        notes: const Value('Sample media log'),
        createdAt: currentDate,
        updatedAt: currentDate,
      ));
      currentDate = currentDate.add(const Duration(days: 1));
    }
    for (final log in mediaLogs) {
      await database.into(database.mediaLogs).insert(log);
    }
    _logger.info('Generated ${mediaLogs.length} media logs');
  }

  /// Tasks and habits
  Future<void> _generateTasksAndHabits() async {
    final tasksHabits = <TasksHabitsCompanion>[];
    tasksHabits.add(TasksHabitsCompanion.insert(
      id: _generateId(),
      userId: 'test-user-1',
      title: 'Daily Exercise',
      type: 'habit',
      scheduleJson: const Value({'frequency': 'daily'}),
      notes: const Value('Stay active every day'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    for (final taskHabit in tasksHabits) {
      await database.into(database.tasksHabits).insert(taskHabit);
    }
    _logger.info('Generated ${tasksHabits.length} tasks and habits');
  }

  /// Travel logs
  Future<void> _generateTravelLogs() async {
    final travelLogs = <TravelLogsCompanion>[];
    travelLogs.add(TravelLogsCompanion.insert(
      id: _generateId(),
      userId: 'test-user-1',
      place: 'Sample Destination',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: Value(DateTime.now()),
      companionsJson: const Value({'companion1': 'John Doe'}),
      cost: const Value(500.0),
      notes: const Value('Sample travel log'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    for (final log in travelLogs) {
      await database.into(database.travelLogs).insert(log);
    }
    _logger.info('Generated ${travelLogs.length} travel logs');
  }

  /// Attachments (sample file references)
  Future<void> _generateAttachments() async {
    final attachments = <AttachmentsCompanion>[
      // Event attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'event',
        objectId: 'event-1', // Placeholder; in real usage, reference actual event IDs
        fileName: 'Conference_Agenda.pdf',
        mime: 'application/pdf',
        localPathOrUrl: '/attachments/events/conference_agenda.pdf',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'event',
        objectId: 'event-2',
        fileName: 'Project_Demo.mp4',
        mime: 'video/mp4',
        localPathOrUrl: '/attachments/events/project_demo.mp4',
        createdAt: DateTime.now(),
      ),

      // Meal attachments (photos)
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'meal',
        objectId: 'meal-1',
        fileName: 'Breakfast_Photo.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/meals/breakfast_photo.jpg',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'meal',
        objectId: 'meal-2',
        fileName: 'Hotpot_Dinner.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/meals/hotpot_dinner.jpg',
        createdAt: DateTime.now(),
      ),

      // Journal attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'journal',
        objectId: 'journal-1',
        fileName: 'Research_Sketch.png',
        mime: 'image/png',
        localPathOrUrl: '/attachments/journals/research_sketch.png',
        createdAt: DateTime.now(),
      ),

      // Career attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'career',
        objectId: 'career-1',
        fileName: 'Internship_Certificate.pdf',
        mime: 'application/pdf',
        localPathOrUrl: '/attachments/career/internship_certificate.pdf',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'career',
        objectId: 'career-2',
        fileName: 'Project_Report.docx',
        mime: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        localPathOrUrl: '/attachments/career/project_report.docx',
        createdAt: DateTime.now(),
      ),

      // Travel attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'travel',
        objectId: 'travel-1',
        fileName: 'Shanghai_Bund_Night.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/travel/shanghai_bund_night.jpg',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'travel',
        objectId: 'travel-2',
        fileName: 'Terracotta_Warriors_Xian.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/travel/xian_terracotta.jpg',
        createdAt: DateTime.now(),
      ),

      // Health attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'health',
        objectId: 'health-1',
        fileName: 'Health_Checkup_2024.pdf',
        mime: 'application/pdf',
        localPathOrUrl: '/attachments/health/health_checkup_2024.pdf',
        createdAt: DateTime.now(),
      ),
    ];

    for (final attachment in attachments) {
      await database.into(database.attachments).insert(attachment);
    }
    _logger.info('Generated attachments: ${attachments.length} records');
  }

  /// Generate embeddings for RAG system
  Future<void> _generateRagEmbeddings() async {
    if (ragPipeline == null) return;

    try {
      final events = await database.select(database.events).get();
      final meals = await database.select(database.meals).get();
      final financeRecords = await database.select(database.financeRecords).get();
      final education = await database.select(database.education).get();
      final career = await database.select(database.career).get();
      final journals = await database.select(database.journals).get();
      final healthMetrics = await database.select(database.healthMetrics).get();
      final tasksHabits = await database.select(database.tasksHabits).get();
      final relations = await database.select(database.relations).get();
      final mediaLogs = await database.select(database.mediaLogs).get();
      final travelLogs = await database.select(database.travelLogs).get();

      final totalDocuments = events.length + meals.length + financeRecords.length +
          education.length + career.length + journals.length +
          healthMetrics.length + tasksHabits.length + relations.length +
          mediaLogs.length + travelLogs.length;

      EmbeddingStatus.startGeneration();

      for (final event in events) {
        try {
          final eventModel = EventModel.fromMap({
            'id': event.id,
            'user_id': event.userId,
            'title': event.title,
            'description': event.description ?? '',
            'tags_json': _extractListFromJsonField(event.tagsJson),
            'date': event.date.toIso8601String(),
            'location': event.location,
            'created_at': event.createdAt.toIso8601String(),
            'updated_at': event.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(eventModel);
        } catch (e) {
          _logger.warning('Error generating embedding for event ${event.id}: $e');
        }
      }

      for (final meal in meals) {
        try {
          final itemsData = meal.itemsJson as Map<String, dynamic>? ?? {};
          final mealModel = MealModel.fromMap({
            'id': meal.id,
            'user_id': meal.userId,
            'name': meal.name,
            'items_json': itemsData,
            'calories_int': meal.caloriesInt,
            'time': meal.time.toIso8601String(),
            'location': meal.location,
            'notes': meal.notes,
            'created_at': meal.createdAt.toIso8601String(),
            'updated_at': meal.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(mealModel);
        } catch (e) {
          _logger.warning('Error generating embedding for meal ${meal.id}: $e');
        }
      }

      for (final record in financeRecords) {
        try {
          final financeModel = FinanceRecordModel.fromMap({
            'id': record.id,
            'user_id': record.userId,
            'title': '${record.category} - ${record.type}',
            'description': record.notes ?? 'No description',
            'amount': record.amount,
            'category': record.category,
            'type': record.type,
            'time': record.time.toIso8601String(),
            'tags_json': _extractListFromJsonField(record.tagsJson),
            'created_at': record.createdAt.toIso8601String(),
            'updated_at': record.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(financeModel);
        } catch (e) {
          _logger.warning('Error generating embedding for finance record ${record.id}: $e');
        }
      }

      for (final edu in education) {
        try {
          final educationModel = EducationModel.fromMap({
            'id': edu.id,
            'user_id': edu.userId,
            'school_name': edu.schoolName,
            'degree': edu.degree,
            'major': edu.major,
            'start_date': edu.startDate.toIso8601String(),
            'end_date': edu.endDate?.toIso8601String(),
            'notes': edu.notes,
            'created_at': edu.createdAt.toIso8601String(),
            'updated_at': edu.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(educationModel);
        } catch (e) {
          _logger.warning('Error generating embedding for education ${edu.id}: $e');
        }
      }

      for (final car in career) {
        try {
          final careerModel = CareerModel.fromMap({
            'id': car.id,
            'user_id': car.userId,
            'company': car.company,
            'role': car.role,
            'start_date': car.startDate.toIso8601String(),
            'end_date': car.endDate?.toIso8601String(),
            'achievements_json': _extractListFromJsonField(car.achievementsJson),
            'notes': car.notes,
            'created_at': car.createdAt.toIso8601String(),
            'updated_at': car.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(careerModel);
        } catch (e) {
          _logger.warning('Error generating embedding for career ${car.id}: $e');
        }
      }

      for (final journal in journals) {
        try {
          final journalModel = JournalModel.fromMap({
            'id': journal.id,
            'user_id': journal.userId,
            'content_md': journal.contentMd,
            'mood_int': journal.moodInt,
            'topics_json': _extractListFromJsonField(journal.topicsJson),
            'created_at': journal.createdAt.toIso8601String(),
            'updated_at': journal.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(journalModel);
        } catch (e) {
          _logger.warning('Error generating embedding for journal ${journal.id}: $e');
        }
      }

      for (final health in healthMetrics) {
        try {
          final healthModel = HealthMetricModel.fromMap({
            'id': health.id,
            'user_id': health.userId,
            'metric_type': health.metricType,
            'value_num': health.valueNum,
            'unit': health.unit,
            'time': health.time.toIso8601String(),
            'notes': health.notes,
            'created_at': health.createdAt.toIso8601String(),
            'updated_at': health.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(healthModel);
        } catch (e) {
          _logger.warning('Error generating embedding for health metric ${health.id}: $e');
        }
      }

      for (final task in tasksHabits) {
        try {
          final taskModel = TaskHabitModel.fromMap({
            'id': task.id,
            'user_id': task.userId,
            'title': task.title,
            'type': task.type,
            'schedule_json': task.scheduleJson,
            'status': task.status,
            'notes': task.notes,
            'created_at': task.createdAt.toIso8601String(),
            'updated_at': task.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(taskModel);
        } catch (e) {
          _logger.warning('Error generating embedding for task/habit ${task.id}: $e');
        }
      }

      for (final relation in relations) {
        try {
          final relationModel = RelationModel.fromMap({
            'id': relation.id,
            'user_id': relation.userId,
            'person_name': relation.personName,
            'relation_type': relation.relationType,
            'notes': relation.notes,
            'important_dates_json': relation.importantDatesJson,
            'created_at': relation.createdAt.toIso8601String(),
            'updated_at': relation.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(relationModel);
        } catch (e) {
          _logger.warning('Error generating embedding for relation ${relation.id}: $e');
        }
      }

      for (final media in mediaLogs) {
        try {
          final mediaModel = MediaLogModel.fromMap({
            'id': media.id,
            'user_id': media.userId,
            'title': media.title,
            'media_type': media.mediaType,
            'progress': media.progress,
            'rating': media.rating,
            'time': media.time.toIso8601String(),
            'notes': media.notes,
            'created_at': media.createdAt.toIso8601String(),
            'updated_at': media.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(mediaModel);
        } catch (e) {
          _logger.warning('Error generating embedding for media log ${media.id}: $e');
        }
      }

      for (final travel in travelLogs) {
        try {
          final travelModel = TravelLogModel.fromMap({
            'id': travel.id,
            'user_id': travel.userId,
            'place': travel.place,
            'start_date': travel.startDate.toIso8601String(),
            'end_date': travel.endDate?.toIso8601String(),
            'companions_json': _extractListFromJsonField(travel.companionsJson),
            'cost': travel.cost,
            'notes': travel.notes,
            'created_at': travel.createdAt.toIso8601String(),
            'updated_at': travel.updatedAt.toIso8601String(),
          });
          await ragPipeline!.ingest(travelModel);
        } catch (e) {
          _logger.warning('Error generating embedding for travel log ${travel.id}: $e');
        }
      }

      _logger.info('Generated embeddings for $totalDocuments records');
      EmbeddingStatus.markComplete();
    } catch (e) {
      _logger.error('Error generating embeddings: $e');
      EmbeddingStatus.markComplete();
    }
  }

  /// Helpers
  String _generateId() {
    return 'test-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1000)}';
  }

  List<String> _extractListFromJsonField(Map<String, dynamic> jsonField) {
    if (jsonField.containsKey('tags')) {
      final tags = jsonField['tags'];
      if (tags is List) {
        return tags.cast<String>();
      }
    }
    return [];
  }

  String _getRandomHomeMadeBreakfast() {
    final foods = ['Oatmeal', 'Scrambled Eggs & Toast', 'Yogurt & Fruit', 'Pancakes', 'Avocado Toast', 'Smoothie Bowl', 'Bagel & Cream Cheese'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomTakeoutBreakfast() {
    final foods = ['Breakfast Burrito', 'Croissant Sandwich', 'Donuts & Coffee', 'Egg Muffin', 'Granola Parfait'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomHomeMadeLunch() {
    final foods = ['Stir-fry with Rice', 'Pasta Bowl', 'Homemade Dumplings', 'Fried Rice', 'Chicken Salad', 'Tomato & Egg Stir-fry'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomTakeoutLunch() {
    final foods = ['Spicy Hotpot Bowl', 'Braised Chicken Rice', 'Lanzhou Noodles', 'Chinese Fast Food', 'Sichuan Rice Bowl', 'Japanese Bento', 'Korean Bibimbap', 'Thai Pad Thai', 'Burgers & Fries'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomHomeMadeDinner() {
    final foods = ['Home-style Dishes', 'Noodle Soup', 'Steamed Egg', 'Vegetable Soup', 'Braised Fish', 'Sweet & Sour Ribs', 'Mapo Tofu'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomTakeoutDinner() {
    final foods = ['Hotpot (delivery)', 'BBQ', 'Pizza', 'Burgers', 'Sushi', 'Korean Fried Chicken', 'Pad Thai', 'Pasta', 'Indian Curry', 'Mexican Burrito', 'Hong Kong Cafe'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomRestaurant() {
    final restaurants = ['Uber Eats', 'DoorDash', 'Campus Canteen', 'Nearby Diner', 'Fast-food Chain', 'Local Restaurant', 'Popular Spot', 'Old Brand Bistro', 'International Cuisine'];
    return restaurants[_random.nextInt(restaurants.length)];
  }

  String _getRandomTakeoutFood() {
    final foods = ['Spicy Hotpot', 'Braised Chicken', 'Lanzhou Noodles', 'Chinese Combo', 'Sichuan Dishes', 'BBQ', 'Burgers', 'Pizza', 'Sushi', 'Fried Chicken', 'Beef Noodles', 'Claypot Rice'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomPriority() {
    final priorities = ['high', 'medium', 'low'];
    return priorities[_random.nextInt(priorities.length)];
  }

  String _getRandomMood() {
    final moods = ['happy', 'nervous', 'calm', 'excited', 'tired', 'satisfied'];
    return moods[_random.nextInt(moods.length)];
  }

  String _getRandomWeather() {
    final weather = ['sunny', 'overcast', 'rainy', 'cloudy', 'snowy'];
    return weather[_random.nextInt(weather.length)];
  }

  String _getRandomMealType() {
    final types = ['breakfast', 'lunch', 'dinner', 'late-night', 'afternoon-tea'];
    return types[_random.nextInt(types.length)];
  }

  String _getRandomPaymentMethod() {
    final methods = ['Credit Card', 'Debit Card', 'Cash', 'Apple Pay', 'Campus Card'];
    return methods[_random.nextInt(methods.length)];
  }

  String _getRandomGroceryStore() {
    final stores = ['Walmart', 'Costco', 'Target', 'Campus Store', 'Convenience Store'];
    return stores[_random.nextInt(stores.length)];
  }

  List<String> _getRandomGroceryItems() {
    final items = ['Milk', 'Bread', 'Eggs', 'Vegetables', 'Fruit', 'Snacks', 'Drinks', 'Instant Noodles', 'Yogurt', 'Meat'];
    final count = _random.nextInt(4) + 2; // 2-5 items
    final selectedItems = <String>[];
    for (int i = 0; i < count; i++) {
      final item = items[_random.nextInt(items.length)];
      if (!selectedItems.contains(item)) {
        selectedItems.add(item);
      }
    }
    return selectedItems;
  }

  String _getRandomTransportType() {
    final types = ['bus', 'subway', 'taxi', 'bike_share', 'ride_hailing', 'campus_shuttle'];
    return types[_random.nextInt(types.length)];
  }

  double _getTransportCost(String type) {
    switch (type) {
      case 'bus':
        return 2.0;
      case 'subway':
        return _random.nextDouble() * 2 + 2; // $2-$4
      case 'taxi':
        return _random.nextDouble() * 15 + 10; // $10-$25
      case 'bike_share':
        return 1.5;
      case 'ride_hailing':
        return _random.nextDouble() * 20 + 10; // $10-$30
      case 'campus_shuttle':
        return 0.0;
      default:
        return 3.0;
    }
  }

  String _getRandomRoute() {
    final routes = ['Campus–Downtown', 'Dorm–Lecture Hall', 'Campus–Train Station', 'Campus–Airport', 'Dorm–Supermarket', 'In-campus commute'];
    return routes[_random.nextInt(routes.length)];
  }

  String _getRandomEntertainment() {
    final types = ['movie', 'karaoke', 'internet_cafe', 'board_games', 'escape_room', 'mystery_game', 'concert', 'exhibition'];
    return types[_random.nextInt(types.length)];
  }

  double _getEntertainmentCost(String type) {
    switch (type) {
      case 'movie':
        return _random.nextDouble() * 15 + 10; // $10-$25
      case 'karaoke':
        return _random.nextDouble() * 60 + 30; // $30-$90
      case 'internet_cafe':
        return _random.nextDouble() * 10 + 5; // $5-$15
      case 'board_games':
        return _random.nextDouble() * 25 + 10; // $10-$35
      case 'escape_room':
        return _random.nextDouble() * 40 + 30; // $30-$70
      case 'mystery_game':
        return _random.nextDouble() * 50 + 40; // $40-$90
      case 'concert':
        return _random.nextDouble() * 120 + 60; // $60-$180
      case 'exhibition':
        return _random.nextDouble() * 20 + 10; // $10-$30
      default:
        return 30.0;
    }
  }

  String _getRandomEntertainmentLocation() {
    final locations = ['City Mall', 'Downtown Plaza', 'Shopping Center', 'Cultural Square', 'Stadium', 'Concert Hall', 'Museum'];
    return locations[_random.nextInt(locations.length)];
  }

  String _getRandomEducationExpense() {
    final types = ['textbooks', 'stationery', 'online_course', 'training_class', 'exam_fee', 'certificate_fee'];
    return types[_random.nextInt(types.length)];
  }

  double _getEducationCost(String type) {
    switch (type) {
      case 'textbooks':
        return _random.nextDouble() * 80 + 40; // $40-$120
      case 'stationery':
        return _random.nextDouble() * 30 + 10; // $10-$40
      case 'online_course':
        return _random.nextDouble() * 200 + 99; // $99-$299
      case 'training_class':
        return _random.nextDouble() * 800 + 400; // $400-$1200
      case 'exam_fee':
        return _random.nextDouble() * 150 + 50; // $50-$200
      case 'certificate_fee':
        return _random.nextDouble() * 100 + 80; // $80-$180
      default:
        return 100.0;
    }
  }

  String _getRandomHealthExpense() {
    final types = ['medicine', 'checkup', 'doctor_visit', 'gym_membership', 'massage', 'therapy'];
    return types[_random.nextInt(types.length)];
  }

  double _getHealthCost(String type) {
    switch (type) {
      case 'medicine':
        return _random.nextDouble() * 30 + 10; // $10-$40
      case 'checkup':
        return _random.nextDouble() * 150 + 80; // $80-$230
      case 'doctor_visit':
        return _random.nextDouble() * 120 + 50; // $50-$170
      case 'gym_membership':
        return _random.nextDouble() * 40 + 20; // $20-$60 (monthly portion)
      case 'massage':
        return _random.nextDouble() * 60 + 40; // $40-$100
      case 'therapy':
        return _random.nextDouble() * 120 + 80; // $80-$200
      default:
        return 60.0;
    }
  }

  String _getRandomShopping() {
    final types = ['clothes', 'shoes', 'makeup', 'electronics', 'books', 'household', 'decor'];
    return types[_random.nextInt(types.length)];
  }

  double _getShoppingCost(String type) {
    switch (type) {
      case 'clothes':
        return _random.nextDouble() * 120 + 40; // $40-$160
      case 'shoes':
        return _random.nextDouble() * 150 + 60; // $60-$210
      case 'makeup':
        return _random.nextDouble() * 120 + 30; // $30-$150
      case 'electronics':
        return _random.nextDouble() * 700 + 150; // $150-$850
      case 'books':
        return _random.nextDouble() * 40 + 10; // $10-$50
      case 'household':
        return _random.nextDouble() * 50 + 20; // $20-$70
      case 'decor':
        return _random.nextDouble() * 80 + 20; // $20-$100
      default:
        return 80.0;
    }
  }

  String _getRandomStore() {
    final stores = ['Amazon', 'Walmart', 'Target', 'Local Shop', 'Specialty Store', 'Shopping Mall', 'Online Platform'];
    return stores[_random.nextInt(stores.length)];
  }

  List<String> _getRandomIngredients() {
    final ingredients = ['Rice', 'Noodles', 'Eggs', 'Greens', 'Chicken', 'Tofu', 'Potato', 'Carrot', 'Onion', 'Garlic', 'Ginger', 'Chili'];
    final count = _random.nextInt(4) + 2; // 2-5
    final selected = <String>[];
    for (int i = 0; i < count; i++) {
      final ingredient = ingredients[_random.nextInt(ingredients.length)];
      if (!selected.contains(ingredient)) {
        selected.add(ingredient);
      }
    }
    return selected;
  }

  String _getRandomSpiciness() {
    final levels = ['none', 'mild', 'medium', 'hot', 'extra-hot'];
    return levels[_random.nextInt(levels.length)];
  }

  String _getRandomTemperature() {
    final temps = ['hot', 'warm', 'cold', 'iced'];
    return temps[_random.nextInt(temps.length)];
  }

  String _getRandomTakeoutComment() {
    final comments = ['tasty', 'large portion', 'a bit salty', 'very flavorful', 'fast delivery', 'nice packaging', 'great value', 'would order again'];
    return comments[_random.nextInt(comments.length)];
  }

  String _getRandomSnack() {
    final snacks = ['Chips', 'Cookies', 'Chocolate', 'Fruit', 'Yogurt', 'Nuts', 'Candy', 'Cake', 'Ice Cream', 'Milk Tea', 'Coffee', 'Juice'];
    return snacks[_random.nextInt(snacks.length)];
  }

  String _getRandomSnackCategory() {
    final categories = ['sweet', 'savory', 'beverage', 'fruit', 'nuts', 'dairy'];
    return categories[_random.nextInt(categories.length)];
  }

  String _getRandomSnackLocation() {
    final locations = ['Convenience Store', 'Supermarket', 'Cafe', 'Bubble Tea Shop', 'Vending Machine', 'Campus Shop'];
    return locations[_random.nextInt(locations.length)];
  }

  String _getRandomSnackComment() {
    final comments = ['study break', 'share with friends', 'energy booster', 'comfort snack', 'perfect for binge-watching'];
    return comments[_random.nextInt(comments.length)];
  }

  /// Relations data
  Future<void> _generateRelationsData() async {
    final relations = <RelationsCompanion>[];
    relations.add(RelationsCompanion.insert(
      id: _generateId(),
      userId: 'test-user-1',
      personName: 'John Doe',
      relationType: const Value('friend'),
      notes: const Value('Met during freshman year'),
      importantDatesJson: const Value({'birthday': '1990-01-01'}),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    for (final relation in relations) {
      await database.into(database.relations).insert(relation);
    }
    _logger.info('Generated ${relations.length} relations data');
  }
}
