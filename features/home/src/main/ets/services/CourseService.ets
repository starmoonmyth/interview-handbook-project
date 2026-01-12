import { hdHttp } from '@itcast/basic'
import { CourseModel, AssignmentModel, AssignmentQuestionModel, AssignmentQuestionData, AssignmentResultModel, CourseHistoryData, StudentProgressData, StudyInfoData } from '../models/CourseModel'

export interface PageResult<T> {
  total: number
  records: T[]
}

export interface JoinCourseParams {
  courseId: number
}

export interface GetAssignmentListParams {
  courseId: number
}

export interface GetAssignmentQuestionsParams {
  assignmentId: number
}

export interface SubmitAssignmentParams {
  assignmentId: number
  answers: Record<string, string>
}

export interface LogStudyParams {
  resourceId: number
}

export class CourseService {
  /**
   * 获取所有课程列表
   */
  static getCourseList() {
    return hdHttp.get<CourseModel[]>('course/list')
  }

  /**
   * 获取课程详情
   * @param id 课程ID
   */
  static getCourseDetail(id: number) {
    return hdHttp.get<CourseModel>(`course/${id}/detail`)
  }

  /**
   * 参加课程
   * @param courseId 课程ID
   */
  static joinCourse(courseId: number) {
    return hdHttp.post<null>('course/join', { courseId: courseId } as JoinCourseParams)
  }

  /**
   * 获取我的课堂列表
   */
  static getMyCourses() {
    return hdHttp.get<CourseModel[]>('course/my')
  }

  /**
   * 获取某课程下的作业列表
   * @param courseId 课程ID
   */
  static getAssignmentList(courseId: number) {
    // 使用 AssignmentModel 接口作为返回类型
    return hdHttp.get<AssignmentModel[]>('assignment/list', { courseId: courseId } as GetAssignmentListParams)
  }

  /**
   * 获取某课程下的试卷列表
   * @param courseId 课程ID
   */
  static getExamList(courseId: number) {
    return hdHttp.get<AssignmentModel[]>('exam/list', { courseId: courseId } as GetAssignmentListParams)
  }

  /**
   * 获取作业下的题目列表
   * @param assignmentId 作业ID
   */
  static getAssignmentQuestions(assignmentId: number) {
    return hdHttp.get<PageResult<AssignmentQuestionData>>('question/list', { assignmentId: assignmentId } as GetAssignmentQuestionsParams)
  }

  /**
   * 提交作业
   * @param data 提交数据 { assignmentId, answers }
   */
  static submitAssignment(data: SubmitAssignmentParams) {
    return hdHttp.post<null>('assignment/submit', data)
  }

  /**
   * 获取作业结果
   * @param assignmentId 作业ID
   */
  static getAssignmentResult(assignmentId: number) {
    return hdHttp.get<AssignmentResultModel>('assignment/result', { assignmentId: assignmentId } as GetAssignmentQuestionsParams)
  }

  /**
   * 获取课程下的学生列表 (包含进度)
   * @param courseId 课程ID
   * @param silent 是否静默请求 (不弹窗报错)
   */
  static getCourseStudents(courseId: number, silent: boolean = false) {
    return hdHttp.get<StudentProgressData[]>('teacher/course/students', { courseId: courseId } as JoinCourseParams, silent)
  }

  /**
   * 获取试卷结果
   * @param assignmentId 试卷ID
   */
  static getExamResult(assignmentId: number) {
    return hdHttp.get<AssignmentResultModel>('exam/result', { assignmentId: assignmentId } as GetAssignmentQuestionsParams)
  }

  /**
   * 记录学习进度
   * @param resourceId 资源ID
   */
  static logStudy(resourceId: number) {
    // 开启 silent 模式，失败时不弹窗
    return hdHttp.post<null>('study/log', { resourceId: resourceId } as LogStudyParams, true)
  }

  /**
   * 获取学习数据信息
   */
  static getStudyInfo() {
    return hdHttp.get<StudyInfoData>('study/info')
  }
}
