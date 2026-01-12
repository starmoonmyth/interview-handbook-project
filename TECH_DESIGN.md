# 技术设计文档 (Technical Design Document)

## 1. 项目概况 (Project Overview)
**项目名称**: Pass Interview (HarmonyOS NEXT) -> 改造为 "学习通" 类教育平台
**目标**: 实现课程资源管理、在线课堂、作业提交、学习分析等核心功能。
**架构**: Modular HarmonyOS (ETS/ArkUI)

## 2. 模块架构 (Module Architecture)

### 2.1 核心模块 (Features)
| 模块名 | 原始功能 | 改造后功能 | 描述 |
| :--- | :--- | :--- | :--- |
| **features/home** | 首页/题库 | **课程资源管理 (Course)** | 展示推荐课程列表，管理课程进度 |
| **features/project** | 项目经验 | **在线课堂 (Classroom)** | 在线直播课、实战项目课堂 |
| **features/interview** | 面试题 | **作业中心 (Assignment)** | 作业发布、提交与状态管理 |
| **features/mine** | 个人中心 | **学习分析 (Analysis)** | 学习时长统计、成绩分析、错题本 |

### 2.2 公共模块 (Commons)
*   **commons/basic**: 基础工具库（网络请求、状态管理、UI组件）。
*   **commons/calendar**: 日历组件（打卡功能）。

## 3. 详细设计 (Detailed Design)

### 3.1 底部导航 (Navigation)
*   **文件**: `products/phone/src/main/ets/views/Index/TabBarComp.ets`
*   **配置**: `products/phone/src/main/ets/contants/index.ets`
*   **变更**:
    *   Tab 1: 课程 (Home)
    *   Tab 2: 作业 (Project) - *注：原Project模块内容更适合作为作业展示*
    *   Tab 3: 课堂 (Interview) - *注：原Interview模块内容更适合作为课堂展示*
    *   Tab 4: 我的 (Mine)

### 3.2 课程模块 (Home Feature)
*   **视图**: `HomeComp.ets`
*   **组件**: `CourseCardComp.ets` (新增) - 展示课程封面、讲师、进度。
*   **模型**: `CourseModel.ets` (新增) - 定义课程数据结构。
*   **逻辑**: 使用 `ForEach` 渲染 `courseList`。

### 3.3 作业模块 (Interview Feature)
*   **视图**: `InterviewComp.ets`
*   **变更**:
    *   顶部搜索框改为“搜索作业”。
    *   Tab分类改为“待提交”和“已完成”。
    *   移除企业推荐部分，专注于作业列表展示。

### 3.4 学习分析模块 (Mine Feature)
*   **视图**: `MineComp.ets`
*   **变更**:
    *   新增数据看板 (`dataBoardBuilder`)：展示累计学时、完成课程、平均成绩。
    *   功能入口调整：我的收藏、错题本、学习笔记。

### 3.5 在线课堂模块 (Project Feature)
*   **视图**: `ProjectComp.ets`
*   **变更**:
    *   标题改为“在线课堂”。
    *   底部提示语改为“更多课程正在赶来的路上…”。

### 3.6 网络配置 (Network Configuration)
*   **文件**: `commons/basic/src/main/ets/constants/NetworkConfig.ets`
*   **功能**: 支持多环境接口切换。
*   **配置项**:
    *   `Mode 1`: 在线生产环境 (默认，使用 `api-harmony-teach.itheima.net`)
    *   `Mode 2`: 本地 Spring Boot 开发环境 (需配置局域网 IP)
*   **使用方式**: 修改 `NetworkConfig.ets` 中的 `BASE_URL` 并重启应用。

## 4. 后续规划 (Future Plan)
1.  **数据接口对接**: 将 Mock 数据替换为真实 API 调用。
2.  **详情页开发**:
    *   课程详情页 (播放器、目录)。
    *   作业详情页 (上传图片/文件、富文本编辑)。
3.  **用户交互**: 增加评论、点赞、收藏的具体实现。

---
*最后更新时间: 2024-05-21*
*注意: 每次修改代码后请务必更新此文档。*
