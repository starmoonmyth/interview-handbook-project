# 教师端后台开发设计文档 (Backend Design Document)

本文档旨在指导后端开发人员（或 AI 助手）构建 "学习通" 类教育平台的 Spring Boot 后端服务。

## 1. 项目概况 (Project Overview)
*   **目标**: 为鸿蒙客户端提供数据支持，并为教师提供一个 Web 端管理后台，用于发布课程、作业和查看学生数据。
*   **技术栈**:
    *   **Language**: Java (JDK 17+)
    *   **Framework**: Spring Boot 3.x
    *   **Database**: MySQL 8.0 / PostgreSQL
    *   **ORM**: MyBatis-Plus 或 Spring Data JPA
    *   **Authentication**: JWT (JSON Web Token)
    *   **API Documentation**: Swagger / Knife4j

## 2. 数据库设计 (Database Schema)

### 2.1 用户表 (users)
用于存储学生和教师信息。
| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | BIGINT | 主键 |
| `username` | VARCHAR | 用户名/账号 |
| `password` | VARCHAR | 加密后的密码 |
| `role` | VARCHAR | 角色: `STUDENT`, `TEACHER`, `ADMIN` |
| `avatar` | VARCHAR | 头像 URL |
| `clockin_numbers` | INT | 累计打卡天数 |
| `total_time` | INT | 累计学习时长 (秒) |

### 2.2 课程表 (courses) - *对应 features/home*
| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | BIGINT | 主键 |
| `title` | VARCHAR | 课程标题 |
| `cover` | VARCHAR | 封面图 URL |
| `teacher` | VARCHAR | 讲师姓名 |
| `description` | TEXT | 课程简介 |
| `created_at` | DATETIME | 创建时间 |

### 2.3 题目/作业表 (questions) - *对应 features/interview*
| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | BIGINT | 主键 |
| `stem` | TEXT | 题干/问题描述 |
| `content` | TEXT | 答案/详细内容 (HTML/Markdown) |
| `difficulty` | TINYINT | 难度 (1-5) |
| `views` | INT | 浏览量 |
| `like_count` | INT | 点赞数 |
| `collect_flag` | BOOLEAN | 是否收藏 (针对特定用户的关联表设计略) |

### 2.4 项目/课堂表 (projects) - *对应 features/project*
| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | BIGINT | 主键 |
| `name` | VARCHAR | 项目/课堂名称 |
| `icon` | VARCHAR | 图标 URL |
| `describe_info` | VARCHAR | 简短描述 |
| `tags` | VARCHAR | 标签 (JSON array 或逗号分隔) |

### 2.5 学习记录表 (study_records)
| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | BIGINT | 主键 |
| `user_id` | BIGINT | 关联用户 ID |
| `question_id` | BIGINT | 关联题目 ID |
| `duration` | INT | 学习时长 (秒) |
| `created_at` | DATETIME | 记录时间 |

## 3. API 接口规范 (API Specification)
> 所有接口建议统一前缀 `/hm/` 以匹配现有 App 配置，或修改 App 端的 `NetworkConfig`。

### 3.1 认证模块 (Auth)
*   `POST /login`: 用户登录
    *   Req: `{ username, password }`
    *   Res: `{ code: 10000, data: { token, userInfo... } }`
*   `GET /userInfo`: 获取用户信息
*   `POST /userInfo/profile`: 更新个人信息

### 3.2 课程/题目模块 (Home & Interview)
*   `GET /question/type`: 获取分类列表
*   `GET /question/list`: 获取题目/课程列表 (分页)
    *   Query: `page`, `pageSize`, `type`
*   `GET /question/{id}`: 获取详情
*   `POST /question/opt`: 收藏/点赞
*   `POST /question/unOpt`: 取消收藏/点赞

### 3.3 课堂模块 (Project)
*   `GET /project/list`: 获取项目/课堂列表
    *   *注: 原 App 调用的是 `question/type` 带参数，建议后端做适配或前端改接口。*

### 3.4 学习数据 (Mine)
*   `POST /clockin`: 每日打卡
*   `GET /clockinInfo`: 获取打卡信息
*   `GET /studyInfo`: 获取学习统计数据
*   `POST /time/tracking`: 上报学习时长

### 3.5 选课与进度 (Student Course Flow) - *新增*
*   `POST /course/join`: 参加课程 (App 课程详情页"立即参加")
    *   Req: `{ courseId }`
    *   *Desc*: 建立用户与课程的关联，上传学生信息供后台查看。
*   `GET /course/my`: 获取"我的课堂" (已参加的课程)
    *   *Res*: 包含 `progress` (进度百分比) 和 `lastStudyTime`。
*   `GET /course/{id}/detail`: 获取课程详情 (含老师介绍)
    *   *Res*: 包含 `isJoined` (是否已参加) 状态字段，供前端判断显示"立即参加"或"进入学习"。

### 3.6 作业提交 (Assignment Submission) - *新增*
*   `POST /assignment/submit`: 提交作业
    *   Req: `{ assignmentId, answers: { questionId: answer... } }`
*   `GET /assignment/result`: 查看作业批改结果 (分数、评语)

## 4. 教师端 Web 后台功能 (Teacher Web Portal)
此部分为 Web 网页端，非 API。

1.  **课程管理**:
    *   列表展示、新建课程、编辑课程、删除课程。
    *   上传课程封面、视频资源。
2.  **作业/题库管理**:
    *   发布新作业（录入题干、答案）。
    *   批改作业（查看学生提交记录）。
3.  **学生与进度管理 (Student Management)**:
    *   **学生列表**: 查看某课程下的所有学生信息 (基于 `user_courses` 表)。
    *   **学习进度**: 查看学生的课程完成度 (类似雨课堂)。
4.  **作业批改中心 (Grading Center)**:
    *   **待批改列表**: 展示学生提交的作业。
    *   **在线批改**: 给主观题打分、写评语。
    *   **成绩统计**: 查看班级平均分、优秀率。

## 5. 开发步骤指南 (Development Guide)
请将此文档发给 AI 助手，并附带以下指令：

> "请基于 `BACKEND_DESIGN.md` 文档，使用 Spring Boot 为我创建一个后端项目。
> 1. 生成 SQL 脚本初始化数据库。
> 2. 创建对应的 Entity, Mapper, Service, Controller 层。
> 3. 实现文档中列出的所有 API 接口，确保返回格式符合 `{ code: 10000, message: 'success', data: ... }` 的标准结构。
> 4. 为教师端编写简单的 Thymeleaf 或 Vue 管理页面。"

