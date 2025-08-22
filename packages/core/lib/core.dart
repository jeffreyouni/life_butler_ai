/// Core domain models, knowledge graph interfaces, RAG pipeline, and advice engine
library core;

// Domain models
export 'src/models/base_model.dart';
export 'src/models/user.dart';
export 'src/models/embedding.dart';

// Knowledge graph
export 'src/kg/kg_interfaces.dart';
export 'src/kg/kg_node.dart';
export 'src/kg/kg_edge.dart';

// RAG pipeline
export 'src/rag/rag_pipeline.dart';
export 'src/rag/rag_pipeline_impl.dart';
export 'src/rag/llm_embedding_service.dart';
export 'src/rag/search_result.dart';
export 'src/rag/chunk_processor.dart';

// Advice engine
export 'src/advice/advice_engine.dart';
export 'src/advice/advice_result.dart';
export 'src/advice/safety_checker.dart';
export 'src/advice/enhanced_response_generator.dart';

// Data quality management
export 'src/quality/data_quality_checker.dart';

// Query planner
export 'src/query/query_planner.dart';
export 'src/query/query_context.dart';

// Request routing system
export 'src/routing/request_router.dart';
export 'src/routing/enhanced_router.dart';
export 'src/routing/request_processor.dart';
export 'src/routing/data_aggregator.dart';
export 'src/routing/real_data_aggregator.dart';

// Domain data management
// Domain layer
export 'src/domain/domain_data_retriever.dart';
export 'src/data/data_access_delegate.dart';

// Utils
export 'src/utils/vector_utils.dart';
export 'src/utils/text_utils.dart';
export 'src/utils/logger.dart';
