# Life Butler AI

🤖 **您的个人AI驱动生活管理助手**

Life Butler AI 是一个隐私优先、本地优先的个人生活管理系统，它将彻底改变您组织、查询和从日常活动中获得见解的方式。采用 Flutter 构建精美的桌面体验，并由尖端的 RAG（检索增强生成）技术驱动，它是您管理从健康记录到财务规划等一切事务的智能伴侣。

## ✨ 为什么选择 Life Butler AI？

**🔐 隐私设计**
- 所有个人数据都保存在您的设备上 - 无需云存储
- 使用 Ollama 进行本地 AI 处理 - 您的对话永远不会离开您的计算机
- 完全控制您的信息

**🧠 智能且上下文感知**
- 用自然语言询问您的生活问题："上个月我在杂货上花了多少钱？"
- 基于 RAG 的响应，使用您的实际数据提供准确、个性化的见解
- 跨所有活动的智能分类和模式识别

**📊 全面的生活跟踪**
- **健康与保健**：跟踪症状、药物、运动、睡眠模式
- **财务管理**：支出、收入、预算和消费分析
- **膳食规划**：食物日志、营养跟踪、食谱管理
- **事件管理**：日历集成、任务跟踪、目标设定
- **学习与成长**：教育进度、技能发展、日记条目
- **更多功能**：统一系统中的 14 个集成生活领域

**🛠️ 开发者友好的架构**
- 清晰的多包单仓库结构
- 模块化设计 - 交换 AI 提供者、扩展 UI 或集成新数据源
- 纯 Dart 业务逻辑与 UI 关注点分离
- 全面的测试覆盖和文档

## 🚀 项目亮点
- **apps/desktop** — 具有现代直观 UI 的 Flutter Material 3 桌面应用
- **packages/core** — 纯 Dart 业务逻辑和 RAG 管道实现
- **packages/data** — 包含所有生活领域的 14 表架构的 Drift ORM
- **packages/providers_llm** — 灵活的 AI 提供者抽象（包含 Ollama 集成）

## 🚀 快速开始（开发）

### 手动设置

1. **为每个包安装依赖项：**

   ```powershell
   # 从 PowerShell (Windows)
   cd apps\desktop; flutter pub get; cd ..\..\packages\core; dart pub get; cd ../data; dart pub get; cd ../providers_llm; dart pub get; cd ..\..
   ```

2. **复制 Ollama 集成的环境模板：**

   ```powershell
   copy apps\desktop\.env.example apps\desktop\.env
   ```

3. **生成 Drift ORM 代码（必需步骤）：**

   ```powershell
   cd packages\data
   dart run build_runner build
   cd ..\..
   ```

4. **安装所需的 Ollama 模型（推荐用于完整 AI 功能）：**

   ```powershell
   ollama pull mistral:latest
   ollama pull nomic-embed-text:latest
   ```

5. **启动桌面应用：**

   ```powershell
   cd apps\desktop
   flutter run -d windows
   ```

## 🏗️ 架构与关键组件

**两阶段初始化：**
- 阶段 1：不带嵌入的基础数据种子（`AppInitializer.initializeBasicData()`）
- 阶段 2：使用 Riverpod 上下文生成 RAG 嵌入（`AppInitializer.initializeEmbeddings()`）

**增强的 3 阶段请求路由器：**
1. **基于规则的分类**（快速、多语言关键词）
2. **语义相似性**（基于嵌入的匹配）
3. **LLM 分类**（用于复杂/模糊查询）

**RAG 管道功能：**
- 存储为二进制 BLOB 的本地向量嵌入
- 内存余弦相似性搜索（`VectorUtils.cosineSimilarity`）
- 具有基于重叠分割的上下文感知分块
- 实时嵌入状态跟踪

## 📁 要探索的关键文件

- **应用入口**：`apps/desktop/lib/main.dart`
- **路由逻辑**：`packages/core/lib/src/routing/enhanced_router.dart`
- **数据库架构**：`packages/data/lib/src/database/tables.dart`
- **RAG 实现**：`packages/core/lib/src/rag/rag_pipeline_impl.dart`
- **应用初始化**：`apps/desktop/lib/services/app_initializer.dart`
- **提供者设置**：`apps/desktop/lib/providers/app_providers.dart`

## 🔧 开发注意事项

**首次克隆项目后：**
```powershell
# 必须先生成 Drift ORM 代码，否则会出现编译错误
cd packages\data
dart run build_runner build
```

**修改 Drift 表架构后：**
```powershell
cd packages\data
dart run build_runner build --delete-conflicting-outputs
```

**故障排除：**
- **克隆后编译错误**：确保先执行 `dart run build_runner build` 生成必需的数据库代码
- 如果桌面应用无法运行，请尝试 `flutter doctor` 并验证是否安装了所需的 SDK
- 确保 Ollama 服务在 `http://localhost:11434` 运行以使用 AI 功能

**测试：**
```powershell
# 测试单个包
cd packages\core && dart test
cd packages\data && dart test

# 运行带调试的桌面应用
cd apps\desktop && flutter run -d windows --verbose
```

## 🤝 贡献

我们欢迎贡献！请：
- 在提交 PR 之前开启 issue 描述较大的更改
- 保持包边界清晰（`packages/core` 中不要有 Flutter 依赖）
- 遵循现有的代码风格和模式
- 为新功能添加测试

## 📄 许可证

此项目根据 `LICENSE` 文件中指定的条款进行许可。

