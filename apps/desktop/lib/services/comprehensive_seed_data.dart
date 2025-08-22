import 'dart:math';
import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'package:core/core.dart';
import 'embedding_status.dart';

/// Comprehensive SeedData implementation with financial records
class ComprehensiveSeedData {
  static final _logger = Logger('ComprehensiveSeedData');
  
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
    _logger.info('Generating comprehensive sample data...');
    
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
      
      _logger.info('Generated comprehensive sample data');
      
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
    
    // Generate regular events with more variety for better chat testing
    final eventTypes = [
      // Education related
      {'title': 'Advanced Mathematics Class', 'category': 'education', 'location': 'Building A Room 101', 'description': 'Learning calculus and linear algebra'},
      {'title': 'Computer Programming Lab', 'category': 'education', 'location': 'Computer Lab', 'description': 'Python and Java programming practice'},
      {'title': 'English Listening Class', 'category': 'education', 'location': 'Language Lab', 'description': 'Improving English listening and speaking skills'},
      {'title': 'Data Structures & Algorithms', 'category': 'education', 'location': 'Building B Room 205', 'description': 'Learning sorting algorithms and data structures'},
      {'title': 'Machine Learning Seminar', 'category': 'education', 'location': 'Academic Hall', 'description': 'Deep learning and AI frontier technologies'},
      
      // Social activities
      {'title': 'Club Activity', 'category': 'social', 'location': 'Student Activity Center', 'description': 'Attending programming club tech sharing'},
      {'title': '同学聚餐', 'category': 'social', 'location': '校外餐厅', 'description': '和室友一起庆祝生日'},
      {'title': '班级聚会', 'category': 'social', 'location': 'KTV', 'description': '期末考试结束后的放松聚会'},
      {'title': '学术讲座', 'category': 'social', 'location': '大礼堂', 'description': '知名教授的人工智能讲座'},
      {'title': '志愿服务', 'category': 'social', 'location': '社区中心', 'description': '参与社区公益活动'},
      
      // 学习和研究
      {'title': '图书馆学习', 'category': 'study', 'location': '图书馆', 'description': '准备期末考试复习'},
      {'title': '小组讨论', 'category': 'study', 'location': '研讨室', 'description': '课程项目团队协作'},
      {'title': '论文写作', 'category': 'study', 'location': '宿舍', 'description': '完成学期论文和报告'},
      {'title': '实验报告', 'category': 'study', 'location': '宿舍', 'description': '整理实验数据和分析结果'},
      
      // 健康和运动
      {'title': '体育锻炼', 'category': 'health', 'location': '体育馆', 'description': '篮球训练和体能锻炼'},
      {'title': '晨跑', 'category': 'health', 'location': '校园跑道', 'description': '每日晨跑保持身体健康'},
      {'title': '瑜伽课', 'category': 'health', 'location': '健身房', 'description': '舒缓压力和提高柔韧性'},
      {'title': '游泳', 'category': 'health', 'location': '游泳馆', 'description': '游泳锻炼和放松身心'},
      
      // 娱乐活动
      {'title': '看电影', 'category': 'entertainment', 'location': '电影院', 'description': '观看最新上映的科幻电影'},
      {'title': '购物', 'category': 'entertainment', 'location': '商场', 'description': '购买生活用品和衣物'},
      {'title': '游戏时间', 'category': 'entertainment', 'location': '宿舍', 'description': '和室友一起玩游戏放松'},
      {'title': '音乐会', 'category': 'entertainment', 'location': '音乐厅', 'description': '欣赏古典音乐演出'},
      
      // 生活日常
      {'title': '洗衣服', 'category': 'daily', 'location': '洗衣房', 'description': '每周定期洗衣服'},
      {'title': '打扫宿舍', 'category': 'daily', 'location': '宿舍', 'description': '整理房间和清洁卫生'},
      {'title': '超市购物', 'category': 'daily', 'location': '超市', 'description': '购买日用品和零食'},
      {'title': '理发', 'category': 'daily', 'location': '理发店', 'description': '修剪头发保持整洁'},
      
      // 特殊活动
      {'title': '实习面试', 'category': 'career', 'location': '公司办公室', 'description': '参加暑期实习面试'},
      {'title': '求职准备', 'category': 'career', 'location': '宿舍', 'description': '准备简历和面试材料'},
      {'title': '职业规划讲座', 'category': 'career', 'location': '就业指导中心', 'description': '了解就业前景和职业发展'},
    ];
    
    var currentDate = start;
    while (currentDate.isBefore(end)) {
      // Generate multiple events per day (1-3 events, higher chance for weekdays)
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
          location: Value(isHomeMade ? '宿舍' : '外卖'),
          notes: Value(isHomeMade ? '自制早餐，营养健康' : '外卖早餐，方便快捷'),
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
          location: Value(isHomeMade ? '宿舍' : '外卖'),
          notes: Value(isHomeMade ? '自制午餐，省钱健康' : '外卖午餐，${_getRandomTakeoutComment()}'),
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
          location: Value(isHomeMade ? '宿舍' : '外卖'),
          notes: Value(isHomeMade ? '自制晚餐，丰盛营养' : '外卖晚餐，${_getRandomTakeoutComment()}'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Snacks (40% chance)
      if (_random.nextDouble() > 0.6) {
        final snackName = _getRandomSnack();
        final cost = _random.nextDouble() * 15 + 5; // 5-20 yuan
        
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
            'healthiness': _random.nextInt(3) + 2, // Snacks less healthy
          }),
          caloriesInt: Value(_random.nextInt(200) + 50),
          time: currentDate.add(Duration(hours: 14, minutes: _random.nextInt(240))),
          location: Value(_getRandomSnackLocation()),
          notes: Value('休闲零食，${_getRandomSnackComment()}'),
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

  /// Generate comprehensive finance records - this is key for spending patterns
  Future<void> _generateComprehensiveFinanceRecords(DateTime start, DateTime end) async {
    final records = <FinanceRecordsCompanion>[];
    
    var currentDate = start;
    while (currentDate.isBefore(end)) {
      // Generate takeout spending (60% chance) - critical for the example query
      if (_random.nextDouble() > 0.4) {
        final amount = _random.nextDouble() * 30 + 15; // 15-45 yuan
        final restaurant = _getRandomRestaurant();
        final food = _getRandomTakeoutFood();
        
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('CNY'),
          time: currentDate.add(Duration(hours: _random.nextInt(12) + 8)),
          category: const Value('takeout'),
          tagsJson: Value({
            'tags': ['food', 'takeout', 'dining'],
            'restaurant': restaurant,
            'meal_type': _getRandomMealType(),
            'payment_method': _getRandomPaymentMethod(),
          }),
          notes: Value('外卖订单 - $food (来自$restaurant)'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Generate grocery shopping (40% chance)
      if (_random.nextDouble() > 0.6) {
        final amount = _random.nextDouble() * 80 + 20; // 20-100 yuan
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('CNY'),
          time: currentDate.add(Duration(hours: _random.nextInt(8) + 10)),
          category: const Value('groceries'),
          tagsJson: Value({
            'tags': ['food', 'groceries', 'shopping'],
            'store_type': _getRandomGroceryStore(),
            'items': _getRandomGroceryItems(),
          }),
          notes: Value('超市购物 - ${_getRandomGroceryItems().join(', ')}'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Generate transportation expenses (daily chance)
      if (_random.nextDouble() > 0.5) {
        final transportType = _getRandomTransportType();
        final amount = _getTransportCost(transportType);
        
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('CNY'),
          time: currentDate.add(Duration(hours: _random.nextInt(16) + 6)),
          category: const Value('transportation'),
          tagsJson: Value({
            'tags': ['transport', 'daily'],
            'transport_type': transportType,
            'route': _getRandomRoute(),
          }),
          notes: Value('交通费用 - $transportType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Generate entertainment expenses (30% chance)
      if (_random.nextDouble() > 0.7) {
        final entertainmentType = _getRandomEntertainment();
        final amount = _getEntertainmentCost(entertainmentType);
        
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('CNY'),
          time: currentDate.add(Duration(hours: _random.nextInt(8) + 14)),
          category: const Value('entertainment'),
          tagsJson: Value({
            'tags': ['entertainment', 'leisure'],
            'activity_type': entertainmentType,
            'location': _getRandomEntertainmentLocation(),
          }),
          notes: Value('娱乐消费 - $entertainmentType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Generate education expenses (weekly chance)
      if (currentDate.weekday == 3 && _random.nextDouble() > 0.6) { // Wednesday
        final educationType = _getRandomEducationExpense();
        final amount = _getEducationCost(educationType);
        
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('CNY'),
          time: currentDate,
          category: const Value('education'),
          tagsJson: Value({
            'tags': ['education', 'learning'],
            'expense_type': educationType,
          }),
          notes: Value('教育支出 - $educationType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Generate health expenses (random chance)
      if (_random.nextDouble() > 0.85) {
        final healthType = _getRandomHealthExpense();
        final amount = _getHealthCost(healthType);
        
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('CNY'),
          time: currentDate,
          category: const Value('healthcare'),
          tagsJson: Value({
            'tags': ['health', 'medical'],
            'service_type': healthType,
          }),
          notes: Value('医疗健康支出 - $healthType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Generate shopping expenses (20% chance)
      if (_random.nextDouble() > 0.8) {
        final shoppingType = _getRandomShopping();
        final amount = _getShoppingCost(shoppingType);
        
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'expense',
          amount: amount,
          currency: const Value('CNY'),
          time: currentDate,
          category: const Value('shopping'),
          tagsJson: Value({
            'tags': ['shopping', 'retail'],
            'item_type': shoppingType,
            'store': _getRandomStore(),
          }),
          notes: Value('购物消费 - $shoppingType'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Weekly income (allowance)
      if (currentDate.weekday == 1) { // Monday
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'income',
          amount: 500.0, // 500 yuan weekly allowance
          currency: const Value('CNY'),
          time: currentDate,
          category: const Value('allowance'),
          tagsJson: const Value({
            'tags': ['allowance', 'income', 'family'],
            'source': 'family_support',
          }),
          notes: const Value('生活费 - 家庭资助'),
          createdAt: currentDate,
          updatedAt: currentDate,
        ));
      }
      
      // Part-time job income (bi-weekly)
      if (currentDate.weekday == 5 && (currentDate.day % 14 == 0)) { // Every two weeks on Friday
        records.add(FinanceRecordsCompanion.insert(
          id: _generateId(),
          userId: 'test-user-1',
          type: 'income',
          amount: 800.0, // 800 yuan bi-weekly part-time
          currency: const Value('CNY'),
          time: currentDate,
          category: const Value('part_time'),
          tagsJson: const Value({
            'tags': ['income', 'work', 'part_time'],
            'job_type': 'tutoring',
          }),
          notes: const Value('兼职收入 - 家教'),
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

  /// Generate education data
  Future<void> _generateEducationData() async {
    final educations = <EducationCompanion>[
      // High School
      EducationCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        schoolName: '北京市第一中学',
        degree: const Value('高中文凭'),
        major: const Value('理科'),
        startDate: DateTime(2015, 9, 1),
        endDate: Value(DateTime(2018, 6, 30)),
        notes: const Value('高考成绩优秀，数学和物理是强项科目。参加过数学竞赛获得省级二等奖。'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // University
      EducationCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        schoolName: '清华大学',
        degree: const Value('学士学位'),
        major: const Value('计算机科学与技术'),
        startDate: DateTime(2018, 9, 1),
        endDate: Value(DateTime(2022, 6, 30)),
        notes: const Value('GPA 3.8/4.0，专业排名前10%。参与过多个开源项目，获得过优秀学生奖学金。'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Master's (current)
      EducationCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        schoolName: '清华大学',
        degree: const Value('硕士学位'),
        major: const Value('人工智能'),
        startDate: DateTime(2022, 9, 1),
        endDate: Value(DateTime(2025, 6, 30)),
        notes: const Value('专注于机器学习和深度学习研究，导师是AI领域知名专家。正在进行关于自然语言处理的论文研究。'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final education in educations) {
      await database.into(database.education).insert(education);
    }
    _logger.info('Generated education data: ${educations.length} records');
  }

  /// Generate career data
  Future<void> _generateCareerData() async {
    final careers = <CareerCompanion>[
      // Internship 1
      CareerCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        company: '腾讯科技有限公司',
        role: '软件开发实习生',
        startDate: DateTime(2020, 7, 1),
        endDate: Value(DateTime(2020, 9, 1)),
        achievementsJson: const Value({
          'achievement1': '参与微信小程序后端开发',
          'achievement2': '优化数据库查询性能提升30%',
          'achievement3': '获得实习期间优秀员工称号'
        }),
        notes: const Value('在腾讯实习期间主要负责微信小程序的后端API开发，学习了大规模系统架构设计。'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Internship 2
      CareerCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        company: '字节跳动科技有限公司',
        role: '算法工程师实习生',
        startDate: DateTime(2021, 7, 1),
        endDate: Value(DateTime(2021, 10, 1)),
        achievementsJson: const Value({
          'achievement1': '参与推荐算法优化项目',
          'achievement2': '实现了A/B测试框架',
          'achievement3': '算法效果提升15%',
        }),
        notes: const Value('在字节跳动实习期间专注于推荐算法的研发，接触了最新的深度学习技术栈。'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Part-time current
      CareerCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        company: '智能教育科技公司',
        role: '机器学习工程师（兼职）',
        startDate: DateTime(2023, 3, 1),
        endDate: const Value(null),
        achievementsJson: const Value({
          'achievement1': '开发AI辅助教学系统',
          'achievement2': '构建学生学习行为分析模型',
          'achievement3': '系统已在5所学校试点应用'
        }),
        notes: const Value('在读研期间的兼职工作，将学术研究与实际应用相结合，开发智能教育产品。'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final career in careers) {
      await database.into(database.career).insert(career);
    }
    _logger.info('Generated career data: ${careers.length} records');
  }

  /// Generate journal entries
  Future<void> _generateJournalEntries(DateTime start, DateTime end) async {
    final journals = <JournalsCompanion>[];
    final journalTopics = [
      ['学习', '研究', '论文'],
      ['生活', '心情', '思考'],
      ['项目', '编程', '技术'],
      ['运动', '健康', '锻炼'],
      ['社交', '朋友', '聚会'],
      ['读书', '知识', '成长'],
      ['旅行', '探索', '体验'],
      ['家庭', '亲情', '关爱'],
    ];

    final journalContents = [
      '''# 今日学习总结

今天主要在研究深度学习的新论文，特别是关于Transformer架构的最新改进。发现了一个很有趣的注意力机制优化方法，可能对我的研究有帮助。

## 重要发现
- 新的位置编码方法可以提升长序列处理能力
- 计算效率提升了约20%
- 准备在下周的组会上分享这个发现

明天计划继续深入研究相关的实现细节。''',

      '''# 生活感悟

最近感觉研究生生活的压力越来越大，但也越来越充实。每天都在学习新的知识，虽然有时候会遇到困难，但解决问题后的成就感是无法替代的。

今天和导师讨论了研究方向，获得了很多有价值的建议。感谢导师的耐心指导。

## 今日心情
😊 总体还是很积极的，对未来充满期待。''',

      '''# 项目进展记录

今天完成了推荐系统的初版实现，主要功能包括：

1. 用户行为数据收集
2. 特征工程处理
3. 模型训练和评估
4. 在线推理服务

## 技术栈
- Python + PyTorch
- FastAPI + Redis
- PostgreSQL + Docker

下一步需要优化算法效果，争取在下周达到预期指标。''',

      '''# 运动日记

今天去学校健身房锻炼了1.5小时，感觉身体状态比之前好了很多。

## 今日训练
- 跑步机 30分钟 (6km)
- 力量训练 45分钟
- 拉伸放松 15分钟

坚持运动真的能提升学习效率，明天继续！💪''',

      '''# 读书笔记

今天读了《深度学习》这本书的第8章，关于卷积神经网络的内容。

## 重要概念
- 卷积操作的数学原理
- 池化层的作用机制
- 不同激活函数的特性

结合最近的项目实践，对CNN的理解更加深入了。理论与实践相结合才能真正掌握知识。''',

      '''# 社交生活

今天和同学们一起去吃了火锅，聊了很多学习和生活的话题。发现大家都有各自的困扰和挑战，但也都在努力成长。

## 感想
- 多与他人交流很重要
- 适当的放松有助于调节心情
- 友谊是珍贵的财富

明天要继续专心学习，但也要记得保持生活的平衡。''',
    ];

    // Generate journal entries over the time period
    final totalDays = end.difference(start).inDays;
    final journalFrequency = (totalDays / 15).ceil(); // Roughly every 4 days
    
    for (int i = 0; i < journalFrequency; i++) {
      final entryDate = start.add(Duration(days: _random.nextInt(totalDays)));
      final topics = journalTopics[_random.nextInt(journalTopics.length)];
      final content = journalContents[_random.nextInt(journalContents.length)];
      final mood = _random.nextInt(10) + 1; // 1-10 mood scale

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

  /// Generate finance records
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

  /// Generate health metrics
  Future<void> _generateHealthMetrics(DateTime start, DateTime end) async {
    final healthMetrics = <HealthMetricsCompanion>[];
    var currentDate = start;
    while (currentDate.isBefore(end)) {
      healthMetrics.add(HealthMetricsCompanion.insert(
        id: _generateId(),
        userId: 'test-user-1',
        metricType: 'weight',
        valueNum: _random.nextDouble() * 100,
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

  /// Generate media logs
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

  /// Generate tasks and habits
  Future<void> _generateTasksAndHabits() async {
    final tasksHabits = <TasksHabitsCompanion>[];
    tasksHabits.add(TasksHabitsCompanion.insert(
      id: _generateId(),
      userId: 'test-user-1',
      title: 'Daily Exercise',
      type: 'habit',
      scheduleJson: const Value({'frequency': 'daily'}),
      notes: const Value('Sample task or habit'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    for (final taskHabit in tasksHabits) {
      await database.into(database.tasksHabits).insert(taskHabit);
    }
    _logger.info('Generated ${tasksHabits.length} tasks and habits');
  }

  /// Generate travel logs
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

  /// Generate attachments (sample file references)
  Future<void> _generateAttachments() async {
    final attachments = <AttachmentsCompanion>[
      // Event attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'event',
        objectId: 'event-1', // This would reference actual event IDs in real scenario
        fileName: '学术会议议程.pdf',
        mime: 'application/pdf',
        localPathOrUrl: '/attachments/events/conference_agenda.pdf',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'event',
        objectId: 'event-2',
        fileName: '项目演示视频.mp4',
        mime: 'video/mp4',
        localPathOrUrl: '/attachments/events/project_demo.mp4',
        createdAt: DateTime.now(),
      ),

      // Meal attachments (photos)
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'meal',
        objectId: 'meal-1',
        fileName: '早餐照片.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/meals/breakfast_photo.jpg',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'meal',
        objectId: 'meal-2',
        fileName: '火锅聚餐.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/meals/hotpot_dinner.jpg',
        createdAt: DateTime.now(),
      ),

      // Journal attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'journal',
        objectId: 'journal-1',
        fileName: '研究笔记草图.png',
        mime: 'image/png',
        localPathOrUrl: '/attachments/journals/research_sketch.png',
        createdAt: DateTime.now(),
      ),

      // Career attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'career',
        objectId: 'career-1',
        fileName: '实习证明.pdf',
        mime: 'application/pdf',
        localPathOrUrl: '/attachments/career/internship_certificate.pdf',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'career',
        objectId: 'career-2',
        fileName: '项目成果报告.docx',
        mime: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        localPathOrUrl: '/attachments/career/project_report.docx',
        createdAt: DateTime.now(),
      ),

      // Travel attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'travel',
        objectId: 'travel-1',
        fileName: '上海外滩夜景.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/travel/shanghai_bund_night.jpg',
        createdAt: DateTime.now(),
      ),
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'travel',
        objectId: 'travel-2',
        fileName: '西安兵马俑.jpg',
        mime: 'image/jpeg',
        localPathOrUrl: '/attachments/travel/xian_terracotta.jpg',
        createdAt: DateTime.now(),
      ),

      // Health attachments
      AttachmentsCompanion.insert(
        id: _generateId(),
        objectType: 'health',
        objectId: 'health-1',
        fileName: '体检报告2024.pdf',
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
      // Get all data and calculate total documents
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
      
      // Start embedding generation (simple loading state)
      EmbeddingStatus.startGeneration();
      
      // Generate embeddings for events
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
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
      
      // Generate embeddings for meals
      for (int i = 0; i < meals.length; i++) {
        final meal = meals[i];
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
      
      // Generate embeddings for finance records
      for (int i = 0; i < financeRecords.length; i++) {
        final record = financeRecords[i];
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
      
      // Generate embeddings for education records
      for (int i = 0; i < education.length; i++) {
        final edu = education[i];
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
      
      // Generate embeddings for career records
      for (int i = 0; i < career.length; i++) {
        final car = career[i];
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
      
      // Generate embeddings for journal entries
      for (int i = 0; i < journals.length; i++) {
        final journal = journals[i];
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
      
      // Generate embeddings for health metrics
      for (int i = 0; i < healthMetrics.length; i++) {
        final health = healthMetrics[i];
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
      
      // Generate embeddings for tasks and habits
      for (int i = 0; i < tasksHabits.length; i++) {
        final task = tasksHabits[i];
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
      
      // Generate embeddings for relations
      for (int i = 0; i < relations.length; i++) {
        final relation = relations[i];
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
      
      // Generate embeddings for media logs
      for (int i = 0; i < mediaLogs.length; i++) {
        final media = mediaLogs[i];
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
      
      // Generate embeddings for travel logs
      for (int i = 0; i < travelLogs.length; i++) {
        final travel = travelLogs[i];
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
      // 标记嵌入生成完成
      EmbeddingStatus.markComplete();
    } catch (e) {
      _logger.error('Error generating embeddings: $e');
      // Even on error, mark as complete to stop loading
      EmbeddingStatus.markComplete();
    }
  }

  /// Helper methods for random data generation
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
    final foods = ['鸡蛋面条', '豆浆油条', '稀饭咸菜', '牛奶面包', '蒸蛋羹', '小米粥', '煎蛋吐司', '燕麦粥', '蒸饺', '包子豆浆'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomTakeoutBreakfast() {
    final foods = ['煎饼果子', '包子粥', '豆浆包子', '胡辣汤', '肉夹馍', '生煎包', '豆腐脑', '小笼包', '烧饼豆浆', '手抓饼'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomHomeMadeLunch() {
    final foods = ['米饭炒菜', '面条汤', '饺子', '炒饭', '蛋炒饭', '青椒肉丝', '宫保鸡丁', '红烧肉', '番茄鸡蛋', '酸辣土豆丝'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomTakeoutLunch() {
    final foods = ['麻辣烫', '黄焖鸡米饭', '兰州拉面', '沙县小吃', '重庆小面', '川菜盖饭', '东北菜', '湘菜', '粤菜', '日式料理', '韩式拌饭', '泰式炒河粉'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomHomeMadeDinner() {
    final foods = ['家常菜', '汤面', '炒菜米饭', '蒸蛋', '蔬菜汤', '红烧鱼', '糖醋排骨', '麻婆豆腐', '回锅肉', '鱼香肉丝'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomTakeoutDinner() {
    final foods = ['火锅外卖', '烧烤', '披萨', '汉堡', '日料', '韩式炸鸡', '泰式炒河粉', '意大利面', '印度咖喱', '墨西哥卷饼', '中式快餐', '港式茶餐厅'];
    return foods[_random.nextInt(foods.length)];
  }

  String _getRandomRestaurant() {
    final restaurants = ['美团外卖', '饿了么', '学校食堂', '附近餐厅', '连锁快餐', '本地餐厅', '网红店', '老字号', '外国料理店'];
    return restaurants[_random.nextInt(restaurants.length)];
  }

  String _getRandomTakeoutFood() {
    final foods = ['麻辣烫', '黄焖鸡', '兰州拉面', '沙县小吃', '川菜', '火锅', '烧烤', '汉堡', '披萨',
                  '寿司', '麻辣香锅', '炸鸡', '牛肉面', '煲仔饭', '盖浇饭', '东北菜', '湘菜', '粤菜'];
    return foods[_random.nextInt(foods.length)];
  }
  
  // New helper methods for expanded data generation
  String _getRandomPriority() {
    final priorities = ['高', '中', '低'];
    return priorities[_random.nextInt(priorities.length)];
  }
  
  String _getRandomMood() {
    final moods = ['开心', '紧张', '平静', '兴奋', '疲惫', '满意'];
    return moods[_random.nextInt(moods.length)];
  }
  
  String _getRandomWeather() {
    final weather = ['晴天', '阴天', '雨天', '多云', '雪天'];
    return weather[_random.nextInt(weather.length)];
  }
  
  String _getRandomMealType() {
    final types = ['早餐', '午餐', '晚餐', '夜宵', '下午茶'];
    return types[_random.nextInt(types.length)];
  }
  
  String _getRandomPaymentMethod() {
    final methods = ['微信支付', '支付宝', '银行卡', '现金', '校园卡'];
    return methods[_random.nextInt(methods.length)];
  }
  
  String _getRandomGroceryStore() {
    final stores = ['华润万家', '永辉超市', '沃尔玛', '家乐福', '校内超市', '便利店'];
    return stores[_random.nextInt(stores.length)];
  }
  
  List<String> _getRandomGroceryItems() {
    final items = ['牛奶', '面包', '鸡蛋', '蔬菜', '水果', '零食', '饮料', '方便面', '酸奶', '肉类'];
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
    final types = ['公交车', '地铁', '出租车', '共享单车', '网约车', '校车'];
    return types[_random.nextInt(types.length)];
  }
  
  double _getTransportCost(String type) {
    switch (type) {
      case '公交车': return 2.0;
      case '地铁': return _random.nextDouble() * 4 + 3; // 3-7 yuan
      case '出租车': return _random.nextDouble() * 20 + 15; // 15-35 yuan
      case '共享单车': return 1.5;
      case '网约车': return _random.nextDouble() * 25 + 10; // 10-35 yuan
      case '校车': return 1.0;
      default: return 5.0;
    }
  }
  
  String _getRandomRoute() {
    final routes = ['学校-市中心', '宿舍-教学楼', '学校-火车站', '学校-机场', '宿舍-超市', '校内通勤'];
    return routes[_random.nextInt(routes.length)];
  }
  
  String _getRandomEntertainment() {
    final types = ['电影', 'KTV', '网吧', '桌游', '密室逃脱', '剧本杀', '音乐会', '展览'];
    return types[_random.nextInt(types.length)];
  }
  
  double _getEntertainmentCost(String type) {
    switch (type) {
      case '电影': return _random.nextDouble() * 30 + 25; // 25-55 yuan
      case 'KTV': return _random.nextDouble() * 80 + 40; // 40-120 yuan
      case '网吧': return _random.nextDouble() * 20 + 10; // 10-30 yuan
      case '桌游': return _random.nextDouble() * 40 + 20; // 20-60 yuan
      case '密室逃脱': return _random.nextDouble() * 60 + 50; // 50-110 yuan
      case '剧本杀': return _random.nextDouble() * 80 + 60; // 60-140 yuan
      case '音乐会': return _random.nextDouble() * 200 + 100; // 100-300 yuan
      case '展览': return _random.nextDouble() * 50 + 30; // 30-80 yuan
      default: return 50.0;
    }
  }
  
  String _getRandomEntertainmentLocation() {
    final locations = ['万达广场', '银泰城', '购物中心', '文化广场', '体育馆', '音乐厅', '博物馆'];
    return locations[_random.nextInt(locations.length)];
  }
  
  String _getRandomEducationExpense() {
    final types = ['教材', '文具', '在线课程', '培训班', '考试费', '证书费'];
    return types[_random.nextInt(types.length)];
  }
  
  double _getEducationCost(String type) {
    switch (type) {
      case '教材': return _random.nextDouble() * 80 + 40; // 40-120 yuan
      case '文具': return _random.nextDouble() * 30 + 10; // 10-40 yuan
      case '在线课程': return _random.nextDouble() * 200 + 99; // 99-299 yuan
      case '培训班': return _random.nextDouble() * 1000 + 500; // 500-1500 yuan
      case '考试费': return _random.nextDouble() * 150 + 50; // 50-200 yuan
      case '证书费': return _random.nextDouble() * 100 + 80; // 80-180 yuan
      default: return 100.0;
    }
  }
  
  String _getRandomHealthExpense() {
    final types = ['药品', '体检', '看病', '健身卡', '按摩', '心理咨询'];
    return types[_random.nextInt(types.length)];
  }
  
  double _getHealthCost(String type) {
    switch (type) {
      case '药品': return _random.nextDouble() * 50 + 15; // 15-65 yuan
      case '体检': return _random.nextDouble() * 200 + 100; // 100-300 yuan
      case '看病': return _random.nextDouble() * 150 + 50; // 50-200 yuan
      case '健身卡': return _random.nextDouble() * 500 + 200; // 200-700 yuan
      case '按摩': return _random.nextDouble() * 100 + 80; // 80-180 yuan
      case '心理咨询': return _random.nextDouble() * 200 + 150; // 150-350 yuan
      default: return 80.0;
    }
  }
  
  String _getRandomShopping() {
    final types = ['衣服', '鞋子', '化妆品', '电子产品', '书籍', '生活用品', '装饰品'];
    return types[_random.nextInt(types.length)];
  }
  
  double _getShoppingCost(String type) {
    switch (type) {
      case '衣服': return _random.nextDouble() * 200 + 80; // 80-280 yuan
      case '鞋子': return _random.nextDouble() * 300 + 150; // 150-450 yuan
      case '化妆品': return _random.nextDouble() * 150 + 50; // 50-200 yuan
      case '电子产品': return _random.nextDouble() * 1000 + 200; // 200-1200 yuan
      case '书籍': return _random.nextDouble() * 60 + 20; // 20-80 yuan
      case '生活用品': return _random.nextDouble() * 50 + 20; // 20-70 yuan
      case '装饰品': return _random.nextDouble() * 100 + 30; // 30-130 yuan
      default: return 100.0;
    }
  }
  
  String _getRandomStore() {
    final stores = ['淘宝', '京东', '拼多多', '实体店', '专卖店', '商场', '网购平台'];
    return stores[_random.nextInt(stores.length)];
  }
  
  // Additional meal-related helper methods
  List<String> _getRandomIngredients() {
    final ingredients = ['米饭', '面条', '鸡蛋', '青菜', '肉类', '豆腐', '土豆', '胡萝卜', '洋葱', '蒜', '生姜', '辣椒'];
    final count = _random.nextInt(4) + 2; // 2-5 ingredients
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
    final levels = ['不辣', '微辣', '中辣', '重辣', '超辣'];
    return levels[_random.nextInt(levels.length)];
  }
  
  String _getRandomTemperature() {
    final temps = ['热菜', '温菜', '凉菜', '冰菜'];
    return temps[_random.nextInt(temps.length)];
  }
  
  String _getRandomTakeoutComment() {
    final comments = ['味道不错', '份量很足', '有点咸', '很香很好吃', '配送很快', '包装精美', '性价比高', '下次还会点'];
    return comments[_random.nextInt(comments.length)];
  }
  
  String _getRandomSnack() {
    final snacks = ['薯片', '饼干', '巧克力', '水果', '酸奶', '坚果', '糖果', '蛋糕', '冰淇淋', '奶茶', '咖啡', '果汁'];
    return snacks[_random.nextInt(snacks.length)];
  }
  
  String _getRandomSnackCategory() {
                   final categories = ['甜食', '咸食', '饮品', '水果', '坚果', '乳制品'];
    return categories[_random.nextInt(categories.length)];
  }
  
  String _getRandomSnackLocation() {
    final locations = ['便利店', '超市', '咖啡厅', '奶茶店', '自动售货机', '学校商店'];
    return locations[_random.nextInt(locations.length)];
  }
  
  String _getRandomSnackComment() {
    final comments = ['解馋小食', '学习间隙', '和朋友分享', '补充能量', '心情不好时的安慰', '追剧必备'];
    return comments[_random.nextInt(comments.length)];
  }

  /// Generate relations data
  Future<void> _generateRelationsData() async {
    final relations = <RelationsCompanion>[];
    relations.add(RelationsCompanion.insert(
      id: _generateId(),
      userId: 'test-user-1',
      personName: 'John Doe',
      relationType: const Value('friend'),
      notes: const Value('Sample relation'),
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
