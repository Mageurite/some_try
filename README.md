
# Repo Rules

This repo is copied from the last Capstone team’s work.  
You are free to **edit, extend, or refactor** the code in any way as needed.

## Guidelines

- **Keep code clean**: follow a consistent style, add comments for tricky parts.  
- **Commit clearly**: write short but descriptive commit messages.  
- **Don’t break things**: test your changes before pushing.  
- **Update docs**: if you change setup steps or major features, update the README.  
- **Work together**: use branches if needed, but PRs are optional. Just keep changes visible to the team.

---
# Virtual Tutor System

This project is an intelligent digital human mentor system that combines digital human technology, speech synthesis, speech recognition, large language models, and knowledge retrieval functionalities. By integrating multiple advanced technological components, the system achieves real-time conversation, question answering, and learning guidance capabilities.

## Project Structure

The project consists of the following main modules:

- **Frontend Interface** (`frontend/`): React-based user interaction interface
- **Backend Service** (`backend/`): Flask backend service for user authentication, session management, etc.
- **Lip-Sync Module** (`lip-sync/`): Implements real-time digital human audio-video synchronized conversations
- **Text-to-Speech Module** (`tts/`): Service for converting text to speech
- **Large Language Model** (`llm/`): Intelligent dialogue system based on LangGraph and Ollama
- **Knowledge Retrieval System** (`rag/`): Vector database-based knowledge retrieval system

## Core Features

### 1. Real-time Interactive Digital Human

- Support for digital human models: musetalk
- Voice cloning functionality
- WebRTC and virtual camera output
- Action choreography: plays custom videos when not speaking
- Multi-concurrent support
- Support for multiple TTS models
- Unified API interface
- Configurable voice parameters

### 2. Intelligent Dialogue System

- **Intelligent Query Classification**: Automatically determines whether queries need RAG retrieval, web search, or direct answers
- **Multi-Source Retrieval**: Integration with Milvus vector database for personal and public knowledge bases
- **External Web Search**: Uses Tavily Search API for real-time information
- **Content Safety**: Built-in content filtering mechanisms to filter inappropriate content
- **Streaming Responses**: Real-time streaming chat interface
- **Session Management**: Uses SQLite for session history persistence
- **Model Management**: Dynamic switching between different Ollama models



### 3. Comprehensive Graphical Interface System

- **User and Administrator Dual Interfaces**: Provides specialized features and views for different roles
- **User Registration and Authentication**: Complete account management system, including registration, login, and password recovery
- **Interactive Dialogue Interface**: Real-time conversations with digital humans and large language models through a graphical interface
- **Resource Management System**: Support for uploading and managing user-level and global-level RAG knowledge base materials
- **Digital Human Management**: Create, customize, and manage personalized digital human appearances (Talking Head)
- **Conversation History**: View and manage historical conversation records
- **Administrator Console**: User management, system monitoring, and data analysis functions
- **Responsive Design**: Adapts to different device screen sizes

## Installation and Running

This project is developed in a modular fashion, with each component being independent and interacting with others through network APIs. Each module can be installed and run independently, without depending on other parts of the system. This design provides high flexibility and scalability, facilitating deployment and maintenance.

### Deployment Note: Why Docker is Not Used

This project does not use Docker containerization for deployment, primarily based on the following considerations:

1. **High Hardware Resource Requirements**: The system involves local deployment of large language models (LLMs) and video generation components, requiring high GPU resources (approximately 40GB of video memory), exceeding the hardware configuration of most single GPU servers. Packaging Docker images within Docker would lead to nested Docker issues, including GPU mapping conflicts, driver compatibility problems, etc.

2. **Explicit Client Request**: The project client explicitly stated they did not want Docker deployment, mainly considering the system's future ease of development and integration, especially within the client's existing infrastructure. While Docker is convenient for packaging environments, it can restrict flexible modifications to underlying components in some research projects.

3. **Official Course Coordinator Approval**: Based on the above reasons, course coordinator Dr. Basem Suleman has officially approved the use of detailed installation and deployment documentation instead of Docker image deployment, and has explicitly stated that this method can be considered equivalent to meeting deployment requirements.

### Module Installation Instructions

For detailed installation and running steps for each module, please refer to the following README documents:

- **Backend Service**: [backend/README.md](./backend/README.md)
- **Lip-Sync Module**: [lip-sync/README.md](./lip-sync/README.md)
- **Text-to-Speech Module**: [tts/README.md](./tts/README.md)
- **Large Language Model**: [llm/README.md](./llm/README.md)
- **Knowledge Retrieval System**: [rag/README.md](./rag/README.md)
- **Frontend Interface**: [frontend/README.md](./frontend/README.md)

## System Architecture

The system adopts a microservice architecture, with components communicating through APIs:

1. **Web Frontend** communicates with the backend service via HTTP/WebSocket
2. **Backend Service** is responsible for user authentication, session management, and coordination of other services
3. **LLM Service** provides intelligent dialogue capabilities, receiving user input and generating responses
4. **RAG System** provides knowledge retrieval functionality, enriching LLM responses
5. **TTS Service** converts text to speech
6. **Lip-Sync Service** generates lip-synchronized videos for digital humans based on audio

## Project Documentation

Detailed project documentation is located in the `doc/` folder, including the following important documents:

- **User Manual**: Provides complete system usage guidelines, including operation methods for each functional module, interface explanations, and FAQs
- **Technical Documentation**: Details the technical implementation specifics, architecture design, data flow, and algorithm explanations for each module
- **API Documentation**: Provides detailed explanations of all available system APIs, including interface definitions, parameter descriptions, return values, and example usage
- **Test Documentation**: Contains comprehensive test cases, test methods, and result analyses for all available system APIs, ensuring stability and interoperability of system modules
- **System Integration Test Documentation**: Detailed records of functional testing processes and results after system integration, including cross-module interaction tests, end-to-end user scenario tests, performance and load tests, and edge case handling tests, ensuring the entire system works properly in an integrated environment

These documents provide comprehensive reference materials for users with different needs, whether they are regular users, developers, or system administrators.

## Hardware Requirements and Project Completeness

Complete deployment of this project requires an NVIDIA GPU with 48GB or more video memory, primarily due to the high computational demands of large language models and digital human generation modules. If you cannot provide hardware that meets these requirements, you can evaluate the project's completeness and functionality through the following methods:

1. **Reference Test Documentation**: The test documentation in the `doc/` directory provides detailed records of testing processes, results, and performance data for all functional modules
2. **Watch Demo Recordings**: Project presentation recordings demonstrate the complete operation process and actual performance of various functions
3. **Modular Deployment**: Based on your hardware conditions, you can selectively deploy certain low-resource modules for testing

We provide comprehensive documentation and test results to ensure that even with limited hardware conditions, you can fully understand and evaluate the system's functionality and performance.

## Contributors

- UNSW CSE COMP9900 Project Group
- Team: H16CBREAD

## Team Members

| Student ID | Name | Email | Role |
| --- | --- | --- | --- |
| Z5501890 | Yuntao Xu | z5501890@ad.unsw.edu.au | Scrum Master |
| Z5462945 | Chengxin Li | z5462945@ad.unsw.edu.au | Product Owner |
| Z5526892 | Xinghua Wu | z5526892@ad.unsw.edu.au | Team Member |
| Z5510221 | Xiao Liu | z5510221@ad.unsw.edu.au | Team Member |
| Z5472591 | Bowen Lu | z5472591@ad.unsw.edu.au | Team Member |
| Z5473495 | Jialu Yu | z5473495@ad.unsw.edu.au | Team Member |

## References

### Text-to-Speech (TTS) Module References
- **CosyVoice**: [https://github.com/FunAudioLLM/CosyVoice](https://github.com/FunAudioLLM/CosyVoice)
- **SoVITS**: [https://github.com/RVC-Boss/GPT-SoVITS](https://github.com/RVC-Boss/GPT)
- **Tacotron2**: [https://pytorch.org/hub/nvidia_deeplearningexamples_tacotron2/](https://pytorch.org/hub/nvidia_deeplearningexamples_tacotron2/)
- **Edge-TTS**: [https://github.com/rany2/edge-tts](https://github.com/rany2/edge-tts)

### Lip-Sync Module References
- **MuseTalk**: [https://github.com/TMElyralab/MuseTalk](https://github.com/TMElyralab/MuseTalk)
- **LiveTalking**: [https://github.com/lipku/LiveTalking](https://github.com/lipku/LiveTalking)
