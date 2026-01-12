# 前后端对接文档 (App 开发指南) - v2.2 页面重构与进度更新

## 1. 项目愿景与核心流程
本项目正在进行架构升级，目标是打造一个类似 **MOOC + 雨课堂** 的教育平台。
核心业务流程从单纯的"浏览与刷题"转变为 **"选课 -> 互动学习 -> 作业闭环"**。

### 1.1 核心用户旅程 (User Journey)
1.  **登录/注册**: (新增) 师生均需登录。教师使用 Web 端，学生使用 App 端。
2.  **发现课程**: 学生在"首页"浏览所有课程，查看讲师与简介。
3.  **选课 (Join)**: 学生点击"立即参加"，建立与课程的关联 (参考 MOOC)。
4.  **我的课堂**: 学生在"课堂" Tab 查看已参加的课程列表。
5.  **作业与批改**:
    *   学生进入课程，查看作业列表。
    *   在线作答并提交作业。
    *   教师在 Web 端批改（打分/评语）。
    *   学生在 App 端查看成绩和反馈。
6.  **学习进度**: 系统根据作业完成情况计算进度，教师可监控全班进度 (参考雨课堂)。

---

## 2. 接口服务信息 (Base Info)
- **Base URL**: `http://localhost:8080` (本地调试)
- **统一前缀**: `/hm`
- **认证方式**: (新增)
    - 登录成功后获取 `token`。
    - 后续请求需在 Header 中携带 `Authorization: {token}`。
- **响应结构**: `Result<T> { code, message, data }`

---

## 3. 账户与认证体系 (Authentication) - NEW

### 3.1 账户角色
| 角色 (role) | 说明 | 权限 |
| :--- | :--- | :--- |
| **TEACHER** | 教师 | Web端登录，发布管理课程/作业/批改 |
| **STUDENT** | 学生 | App端登录，选课/答题/查看成绩 |
| **ADMIN** | 管理员 | 系统维护 (预留) |

### 3.2 登录接口
- **URL**: `/hm/login`
- **Method**: `POST`
- **Body**: `{ "username": "...", "password": "...", "installTime": "1715328000000" }` (新增 installTime 参数，用于设备限制，替代 macAddress)
- **Response**:
  - 成功: `code: 10000`
  - 失败(超过50台): `code: 403, message: "设备授权已满(Max 50)，禁止登录"`
  ```json
  {
    "code": 10000,
    "data": {
      "token": "uuid-token-string",
      "userInfo": { "id": 1, "username": "...", "role": "STUDENT", "avatar": "..." }
    }
  }
  ```

### 3.3 注册接口 (新增)
- **URL**: `/hm/register`
- **Method**: `POST`
- **Body**: 
  ```json
  { 
    "username": "...", 
    "password": "...", 
    "role": "TEACHER",
    "teacherCode": "TEACHER2025", // (新增) 教师注册必须提供认证码
    "nickName": "..." // (可选) 昵称
  }
  ```
- **Response**:
  ```json
  {
    "code": 10000,
    "message": "注册成功",
    "data": "注册成功"
  }
  ```

### 3.4 个人信息管理 (App/Web)
- **URL**: `/hm/userInfo/profile`
- **Method**: `POST`
- **Headers**: `Authorization: {token}`
- **Body**:
  ```json
  {
    "avatar": "http://...",
    "realName": "张三",       // (新增) 真实姓名，实名认证必填
    "nickName": "飞翔的企鹅", // (新增) 用户昵称 (网名)
    "studentNo": "2024001",   // (新增) 学号，实名认证必填
    "birthday": "2000-01-01",
    "gender": 1,              // (新增) 性别: 1=男, 2=女
    "password": "newPassword" // 可选，不填则不修改
  }

### 3.5 修改密码 (App/Web)
*   **URL**: `/hm/userInfo/password`
*   **Method**: `POST`
*   **Headers**: `Authorization: {token}`
*   **Body**:
    ```json
    {
      "oldPassword": "...",
      "newPassword": "..."
    }
    ```

### 3.6 实名验证流程 (App 端核心) - NEW
学生注册后默认为非实名状态。App 端需在**登录后**或**选课前**引导用户完善信息。
1.  **检查状态**: 调用 `GET /hm/userInfo`，检查 `realName` 和 `studentNo` 字段。
2.  **引导输入**: 若字段为空，弹出“完善个人信息”页面。
3.  **提交验证**: 调用 `POST /hm/userInfo/profile` 提交姓名、学号和性别。
4.  **生效**: 提交成功后，教师端“学生管理”列表将显示该学生的真实姓名。

### 3.6 数据权限
- **教师端**: 只能管理(增删改查)自己创建的课程 (`courses.teacher_id = current_user_id`)。
- **学生端**: 只能查看公开课程或自己已参加的课程。

### 3.7 学习数据 (Mine)
*   `POST /hm/clockin`: 每日打卡
*   `GET /hm/clockinInfo`: 获取打卡信息
*   `GET /hm/studyInfo`: 获取学习统计数据 (增强版)
    *   **Response**:
        ```json
        {
          "code": 10000,
          "data": {
            "pendingTasks": 3,       // 待办任务数 (未读资源 + 未过期且未提交的作业)
            "passRate": "67%",       // 课程通过率 (已通过课程/总课程)
            "courseCount": 2         // 已修课程数
          }
        }
        ```
*   `POST /time/tracking`: 上报学习时长

### 3.8 资源访问注意事项 (Resource Access) - NEW
由于 Android 模拟器/真机无法直接访问 `localhost`，后端返回的资源 URL 会尝试自动转换为本机局域网 IP。
*   **开发建议**:
    1.  确保电脑和手机/模拟器在**同一局域网**。
    2.  如果 App 访问接口使用的是 IP (如 `192.168.1.5:8080`)，则无需额外处理，后端会根据请求 Host 自动拼接。
    3.  如果遇到视频无法播放或图片无法加载，请检查 URL 中的 IP 是否可达。
    4.  `/uploads/**` 路径已配置为**公开访问**，不需要携带 Token。

---

## 4. 接口变更与新增 (API Changes)

### 4.1 课程发现与选课 (Course Discovery & Join)
| 场景 | 接口 | 方法 | 参数 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| 首页列表 | `/hm/course/list` | GET | `page`, `pageSize` | 展示所有公开课程。**注意**: `teacher` 字段已自动填充为讲师真实姓名。 |
| 课程详情 | `/hm/course/{id}/detail` | GET | Path `id` | 获取课程详细介绍。`teacher` 字段为讲师真实姓名。 |
| **立即参加** | `/hm/course/join` | POST | `{ courseId }` | **(新增)** 核心动作。建立 User-Course 关联，初始化学习进度。 |

### 4.2 我的课堂 (My Classroom)
| 场景 | 接口 | 方法 | 参数 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **已选课程** | `/hm/course/my` | GET | 无 | 返回已参加的课程列表。包含 `progress` (进度) 和 `isPassed` (是否合格) 字段。`teacher` 字段为讲师真实姓名。 |
**Response Example**:
```json
{
  "code": 10000,
  "data": [
    {
      "id": 1,
      "courseId": 1,
      "title": "Java 高级编程",
      "cover": "http://...",
      "teacher": "李老师",
      "progress": 50,        // (重点) Integer 类型, 0-100
      "isPassed": false,     // (重点) Boolean 类型, true=合格
      "lastStudyTime": "2023-10-01..."
    }
  ]
}
```

### 4.3 作业与试卷 (Assignment & Exam)
| 场景 | 接口 | 方法 | 参数 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **作业列表** | `/hm/assignment/list` | GET | `courseId` | 仅返回**作业** (Type=HOMEWORK)。包含状态和时间。 |
| **试卷列表** | `/hm/exam/list` | GET | `courseId` | 仅返回**试卷** (Type=EXAM)。包含状态和时间。 |
| 题目列表 | `/hm/question/list` | GET | `assignmentId` | 获取题目列表。 |
| **提交作业** | `/hm/assignment/submit` | POST | JSON | 学生提交作业答案。 |
| **提交试卷** | `/hm/exam/submit` | POST | JSON | 学生提交试卷答案 (严格校验考试时间)。 |
| **查看结果** | `/hm/assignment/result` | GET | `assignmentId` | 查看作业分数、评语。 |
| **查看试卷** | `/hm/exam/result` | GET | `assignmentId` | 查看试卷分数、评语。 |
| **我的成绩** | `/hm/score/my` | GET | `courseId` | 获取某课程下的平时作业与考试成绩统计。 |

### 4.4 作业/考试状态定义 (Status)
App 端需根据返回的 `status` 字段展示不同 UI：
*   **NOT_STARTED** (未开始): 当前时间 < 开始时间。
*   **IN_PROGRESS** (进行中): 开始时间 <= 当前时间 <= 截止时间。
*   **ENDED** (已结束): 当前时间 > 截止时间 (且未提交)。
*   **SUBMITTED** (已提交): 学生已提交，等待批改。
*   **GRADED** (已完成): 教师已批改，可查看成绩和反馈。

### 4.5 学习进度同步 (Study Progress) - NEW
为了准确记录学习进度，App 端需在以下场景调用接口上报进度：

*   **场景 1：资源学习 (Resource)**
    *   **时机**: 用户点击查看视频或下载文档时（即视为“已读”）。
    *   **接口**: `POST /hm/study/log`
    *   **Body**:
        ```json
        {
          "resourceId": 101 // (必填) 资源 ID
        }
        ```

*   **场景 2：作业/考试 (Assignment/Exam)**
    *   **时机**: 提交作业时后端自动计算。
    *   **说明**: 无需额外接口，`submit` 接口已包含进度触发逻辑。

*   **计算规则 (后端逻辑)**:
    *   课程总进度 = (已完成资源数 + 已提交作业数) / (课程总资源数 + 总作业数) * 100
    *   后端会根据上报的日志自动更新 `user_courses` 表中的 `progress` 字段。

### 4.6 作业结果详情 (Assignment Result) - NEW
**接口**: `GET /hm/assignment/result`
**说明**: 获取作业的提交详情、批改结果及题目解析。

**Response**:
```json
{
  "code": 10000,
  "data": {
    "submission": {
      "status": "GRADED",       // SUBMITTED(待批改) | GRADED(已批改)
      "score": 80,              // 总分 (未批改为 null)
      "teacherComment": "不错", // 教师评语
      "createdAt": "2023-01-01 12:00:00"
    },
    "assignment": {
      "title": "Java基础测试",
      "description": "请认真作答"
    },
    "questions": [
      {
        "id": 101,
        "type": "choice",
        "stem": "Java中...",
        "options": "[\"A\",\"B\"]",
        "standardAnswer": "A",
        "studentAnswer": "A. class",
        "isCorrect": true // (后端计算) 是否正确
      },
      {
        "id": 102,
        "type": "blank",
        "standardAnswer": "static",
        "studentAnswer": "final",
        "isCorrect": false
      }
    ]
  }
}
```

---

## 5. 关键数据模型定义 (Data Models)

### 5.1 课程详情模型 (Course Detail)
**接口**: `GET /hm/course/{id}/detail`
```json
{
  "id": 1,
  "title": "Java 高级编程",
  "teacher": "李老师",  // 冗余字段，便于显示
  "teacherId": 101,   // (新增) 关联的教师ID
  "description": "详细介绍...",
  "cover": "...",
  "isJoined": true,       // App 端根据此字段判断显示"立即参加"还是"进入学习"
  "studentCount": 120     // 选课人数
}
```

### 5.2 提交作业模型 (Submit Payload)
**接口**: `POST /hm/assignment/submit`
```json
{
  "assignmentId": 10,
  "answers": {
    "101": "A",           // 选择题 ID: 选项
    "102": "static",      // 填空题 ID: 内容
    "103": "面向对象..."   // 简答题 ID: 内容
  }
}
```

---

## 6. 开发进度与规划 (Progress & Plan)

### 已完成 (Done)
- [x] **后端**: 基础架构 (SpringBoot, MyBatis-Plus, MySQL)。
- [x] **后端**: 课程/章节/资源管理 API (支持视频/文档上传)。
- [x] **Web端**: 教师管理后台 (课程编辑、章节管理、资源上传)。
- [x] **Web端**: 教师登录与权限控制 (Login, Token Auth)。
- [x] **Web端**: 教师注册身份验证 (认证码) 与个人信息管理。
- [x] **数据库**: 更新 `courses` 表添加 `teacher_id`。
- [x] **数据库**: 创建 `user_courses` (选课) 和 `assignment_submissions` (作业提交) 表。
- [x] **后端**: 实现选课接口 `/hm/course/join` 和我的课程 `/hm/course/my`。
- [x] **后端**: 实现作业提交 `/hm/assignment/submit` (含自动判分) 和结果查询 `/hm/assignment/result`。
- [x] **Web端重构 (New)**: 将后台管理页面从单页应用 (SPA) 拆分为多页应用 (MPA)，解决刷新后页面状态丢失问题。
    - `index.html`: 数据看板
    - `courses.html`: 课程管理
    - `questions.html`: 作业/题库
    - `students.html`: 学生管理
    - `grading.html`: 批改中心
    - `profile.html`: 个人中心
    - `admin.html`: 系统管理
- [x] **Web端优化 (New)**: 优化导航逻辑，管理员登录后自动重定向至系统管理页 (`admin.html`)，且不显示数据看板。
- [x] **Web端/后端 (New)**: 修复个人中心信息回显问题，确保真实姓名、生日等字段从数据库实时获取 (移除 Token 缓存导致的旧数据问题)。
- [x] **环境配置 (New)**: 修正数据库连接配置 (`application.properties`) 适配本地环境 (`harmony_learning` 库)。
- [x] **后端**: 优化 `AdminController` 课程列表查询，支持批量获取并优先展示教师真实姓名 (Real Name)，解决只显示账号的问题。
- [x] **后端**: 更新 `TeacherController` 创建课程逻辑，自动将教师真实姓名写入课程记录。
- [x] **后端/Web端**: 学生管理功能升级，支持查看学生考试最高分，及教师手动标记"是否合格" (UserCourse 新增 isPassed 字段)。
- [x] **后端**: 升级 `/hm/course/my` 接口，返回 `isPassed` 状态供 App 端展示。

### 待办 (Todo)
**App (你)**:
1.  **登录页**: 实现学生登录，保存 Token。
2.  **实名认证 (New)**: 登录后检查 `userInfo.realName`，若为空则引导用户填写姓名和学号 (调用 `/hm/userInfo/profile`)。
3.  **首页**: 增加"课程详情页"，设计"立即参加"按钮。
4.  **课堂页**: 新增 Tab，仅展示 `/course/my` 的数据。
5.  **作业页**: 新增"提交"按钮和"查看结果/解析"状态。
6.  **逻辑对接**: 所有 API 请求 Header 需携带 `Authorization: {token}`。

请 App 端 AI 确认以上方案，重点关注认证流程的变更。
